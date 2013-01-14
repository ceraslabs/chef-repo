#
# Cookbook Name:: pattern-deployer
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

database_name = node["pattern_deployer"]["database"]["name"]
username = node["pattern_deployer"]["database"]["username"]
password = node["pattern_deployer"]["database"]["password"]
dbms = node["pattern_deployer"]["database"]["system"]

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
    :host =>  "127.0.0.1"
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

application "pattern-deployer" do
  path node["pattern_deployer"]["deploy_to"]
  repository "https://github.com/ceraslabs/pattern-deployer.git"

  rails do
    database do
      host "localhost"
      database database_name
      username username
      password password
      adapter node["pattern_deployer"]["database"]["adapter"]
    end
  end
end