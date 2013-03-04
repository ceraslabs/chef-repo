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
include_recipe "NestedQEMU::common"

my_databag = data_bag_item(node.name, node.name)

database_info = my_databag["database"] || Hash.new
dbms = database_info["system"] || "mysql"
database_name = database_info["name"] || "mydb"
username = database_info["user"] || "user"
password = database_info["password"] || "mypass"
#port = database_info["port"]

case dbms
when "mysql"
  #node.set['mysql']['port'] = port if port
  node.set['mysql']['bind_address'] = "0.0.0.0"
  node.save

  include_recipe "database::mysql"
  include_recipe "mysql::server"

  db_provider = Chef::Provider::Database::Mysql
  user_provider = Chef::Provider::Database::MysqlUser
  connection_info = {:host => "localhost", :username => "root", :password => node["mysql"]["server_root_password"]}
when "postgresql"
  #node.set['postgresql']['config']['port'] = port if port
  node.set['postgresql']['config']['listen_addresses'] = "*"
  node['postgresql']['pg_hba'] << {:type => "host", :db => "all", :user => "all", :addr => "0.0.0.0/0", :method => "md5"}
  node.save

  include_recipe "database::postgresql"
  include_recipe "postgresql::server"

  db_provider = Chef::Provider::Database::Postgresql
  user_provider = Chef::Provider::Database::PostgresqlUser
  connection_info = {:host => "127.0.0.1", :port => node["postgresql"]["config"]["port"], :username => "postgres", :password => node["postgresql"]["password"]["postgres"]}
else
  raise "Unexpected database DBMS #{dbms}"
end

database_user username do
  connection connection_info
  password password
  provider user_provider
  action :create
  ignore_failure true
end

ruby_block "update_connection_info_password" do
  block do
    connection_info[:password] = password if dbms == "postgresql" && connection_info[:username] == username
  end
end

database database_name do
  connection connection_info
  provider db_provider
  action :create
  ignore_failure true
end

database_user username do
  connection connection_info
  password password
  provider user_provider
  database_name database_name
  host '%'
  action :grant
  ignore_failure false
end

sql_script = my_databag["sql_script_file"]["name"]
sql_script_path = "/tmp/#{sql_script}" if sql_script
unless ::File.exists?(sql_script_path)
  cookbook_file sql_script_path do
    source sql_script
  end

  database database_name do
    connection connection_info
    sql { ::File.open(sql_script_path).read }
    action :query
    ignore_failure false
  end
end