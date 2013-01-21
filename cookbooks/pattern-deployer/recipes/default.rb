user node["pattern_deployer"]["user"]

group node["pattern_deployer"]["group"] do
  members [ node["pattern_deployer"]["user"] ]
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

database database_name do
  connection connection_info
  provider db_provider
  action :create
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

application "pattern-deployer" do
  name "pattern-deployer"
  owner node["pattern_deployer"]["user"]
  group node["pattern_deployer"]["group"]
  path node["pattern_deployer"]["deploy_to"]
  repository "https://github.com/ceraslabs/pattern-deployer.git"
  action :force_deploy # if node.chef_environment == "development"
  migrate true

  rails do
    gems %w{ bundler }

    database do
      host "localhost"
      database database_name
      username username
      password password
      adapter adapter
    end
  end

  passenger_demo do
    service_name node["pattern_deployer"]["service_name"]
  end

  before_restart do
    chef_repo_dir = "#{node["pattern_deployer"]["deploy_to"]}/current/chef-repo"
    chef_config_dir = node["pattern_deployer"]["chef"]["conf_dir"]

    template "#{chef_config_dir}/knife.rb" do
      source "knife.rb.erb"
      owner node["pattern_deployer"]["user"]
      group node["pattern_deployer"]["group"]
      mode 0664
      variables(
        :log_level => :info,
        :log_location => "STDOUT",
        :chef_server_url => node["pattern_deployer"]["chef"]["chef_server_url"],
        :syntax_check_cache_path => File.join(chef_config_dir, "syntax_check_cache")
      )
    end

    template "#{chef_config_dir}/validation.pem" do
      source "validation.pem.erb"
      owner node["pattern_deployer"]["user"]
      group node["pattern_deployer"]["group"]
      mode 0660
    end

    template "#{chef_config_dir}/client.pem" do
      source "client.pem.erb"
      owner node["pattern_deployer"]["user"]
      group node["pattern_deployer"]["group"]
      mode 0660
    end

    execute "upload_all_cookbooks" do
      cwd "#{chef_repo_dir}/cookbooks"
      command "ruby upload_all_cookbooks.rb '#{chef_config_dir}/knife.rb'"
    end

    execute "generate_doc" do
      command "bundle exec ruby generate_doc.rb"
      cwd "#{node["pattern_deployer"]["deploy_to"]}/current"
    end
  end
end