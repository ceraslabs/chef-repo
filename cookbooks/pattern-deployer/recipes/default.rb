#
# Copyright 2013 Marin Litoiu, Hongbin Lu, Mark Shtern, Bradlley Simmons, Mike
# Smit
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

new_user_home = "/home/#{node["pattern_deployer"]["user"]}"

user node["pattern_deployer"]["user"] do
  home new_user_home
  supports(:manage_home => true)
end

group node["pattern_deployer"]["group"] do
  members [ node["pattern_deployer"]["user"] ]
end

node.set["pattern_deployer"]["deploy_to"] = "#{new_user_home}/pattern-deployer"
node.set["pattern_deployer"]["chef"]["api_client_key_path"] = "#{new_user_home}/.chef/client.pem"
node.set["pattern_deployer"]["chef"]["validation_key_path"] = "#{new_user_home}/.chef/validation.pem"
node.save

directory "#{new_user_home}/.chef" do
  owner node["pattern_deployer"]["user"]
  group node["pattern_deployer"]["group"]
end

database_name = node["pattern_deployer"]["database"]["name"]
username = node["pattern_deployer"]["database"]["username"]
password = node["pattern_deployer"]["database"]["password"]
dbms = node["pattern_deployer"]["database"]["system"]
adapter = node["pattern_deployer"]["database"]["adapter"]

case dbms
when "mysql"
  include_recipe "database::mysql"
  include_recipe "mysql::server"

  db_provider = Chef::Provider::Database::Mysql
  user_provider = Chef::Provider::Database::MysqlUser
  connection_info = {
    :host => "localhost",
    :username => "root",
    :password => node["mysql"]["server_root_password"]
  }
when "postgresql"
  include_recipe "database::postgresql"
  include_recipe "postgresql::server"

  db_provider = Chef::Provider::Database::Postgresql
  user_provider = Chef::Provider::Database::PostgresqlUser
  connection_info = {
    :host =>  "127.0.0.1",
    :port => node["postgresql"]["config"]["port"],
    :username => "postgres",
    :password => node["postgresql"]["password"]["postgres"]
  }
else
  raise "Unexpected database DBMS #{dbms}"
end

database_user username do
  connection connection_info
  password password
  provider user_provider
  action :create
end

ruby_block "update_connection_info_password" do
  block do
    if dbms == "postgresql" && connection_info[:username] == username
      connection_info[:password] = password
    end
  end
end

database_user username do
  connection connection_info
  password password
  provider user_provider
  database_name database_name
  host "localhost"
  action :grant
end

include_recipe "git"

node.set["languages"]["ruby"]["default_version"] = "1.8"
node.save

include_recipe "ruby"
include_recipe "ruby::symlinks"

script "install_rubygems" do
  interpreter "bash"
  cwd "/tmp"
  code <<-EOH
    curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
    tar zxf rubygems-1.8.10.tgz
    sudo ruby rubygems-1.8.10/setup.rb --no-format-executable
  EOH
end

application "pattern-deployer" do
  name "pattern-deployer"
  owner node["pattern_deployer"]["user"]
  group node["pattern_deployer"]["group"]
  path node["pattern_deployer"]["deploy_to"]
  repository "https://github.com/ceraslabs/pattern-deployer.git"
  action :force_deploy # if node.chef_environment == "development"

  rails do
    database do
      host "localhost"
      database database_name
      username username
      password password
      adapter adapter
    end

    restart_command do
      execute "stop_the_app" do
        command "bundle exec passenger stop -p 80"
        cwd "#{node["pattern_deployer"]["deploy_to"]}/current"
        ignore_failure true
      end

      execute "start_the_app" do
        command "bundle exec passenger start -p 80 -e production -d --user=#{node["pattern_deployer"]["user"]}"
        cwd "#{node["pattern_deployer"]["deploy_to"]}/current"
      end
    end
  end

  before_restart do
    template node["pattern_deployer"]["chef"]["validation_key_path"] do
      source "validation.pem.erb"
      owner node["pattern_deployer"]["user"]
      group node["pattern_deployer"]["group"]
      mode 0660
    end

    template node["pattern_deployer"]["chef"]["api_client_key_path"] do
      source "client.pem.erb"
      owner node["pattern_deployer"]["user"]
      group node["pattern_deployer"]["group"]
      mode 0660
    end

    # install passenger dependencies
    case node["platform"]
    when "ubuntu"
      packages = %w{ libssl-dev libcurl4-openssl-dev libxslt-dev libxml2-dev }
    else
      #TODO
    end

    packages.each do |package|
      package package
    end

    %w{ mixlib-cli json }.each do |gem|
      gem_package gem
    end

    execute "setup_the_app" do
      command "ruby setup.rb production "\
                 "--defaults "\
                 "--as-user #{node["pattern_deployer"]["user"]} "\
                 "--db-user '#{username}' "\
                 "--db-password '#{password}' "\
                 "--db-name '#{database_name}' "\
                 "--chef-client-key '#{node["pattern_deployer"]["chef"]["api_client_key_path"]}' "\
                 "--chef-client-name '#{node["pattern_deployer"]["chef"]["api_client_name"]}' "\
                 "--chef-server '#{node["pattern_deployer"]["chef"]["chef_server_url"]}' "\
                 "--chef-validation-key '#{node["pattern_deployer"]["chef"]["validation_key_path"]}' "

      cwd "#{node["pattern_deployer"]["deploy_to"]}/current"
    end
  end
end