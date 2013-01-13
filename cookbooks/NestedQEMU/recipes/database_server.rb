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
  #node.save

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
end

database_user username do
  connection connection_info
  password password
  provider user_provider
  database_name database_name
  host '%'
  action :grant
end

my_sql_script = my_databag["sql_script_file"]["name"]
if my_sql_script  
  cookbook_file "/tmp/#{my_sql_script}" do
    source my_sql_script
  end
  
  database database_name do
    connection connection_info
    sql { ::File.open("/tmp/#{my_sql_script}").read }
    action :query
  end
end

=begin
# install mysql
mysql_installed = !`dpkg --get-selections | grep mysql`.empty?
unless mysql_installed
  include_recipe "NestedQEMU::common"

  # install mysql
  node["mysql"]["server_root_password"] = mysql_root_password
  node.save
  include_recipe "mysql::client"
  include_recipe "mysql::server"

  template "/tmp/grants.sql" do
    source "grants.sql.erb"
    mode "0600"
    variables(
      :database => database_name,
      :username => mysql_username,
      :password => mysql_password
    )
  end

  execute "set-mysql-remote-access-privileges" do
    command "mysql -u root -p#{mysql_root_password} < /tmp/grants.sql"
  end
end

my_sql_script = my_databag["sql_script_file"]["name"]
if my_sql_script
  execute "create database" do
    command "mysql -uroot -p#{mysql_root_password} -e 'create database if not exists #{database_name}'"
  end

  cookbook_file "/tmp/#{my_sql_script}" do
    source my_sql_script
  end

  execute "run db script" do
    command "mysql -uroot -p#{mysql_root_password} -D #{database_name} < /tmp/#{my_sql_script}"
  end
end

template "/etc/mysql/my.cnf" do
  source "my.cnf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[mysql]"
end

service "mysql" do
  supports :status => true, :restart => true
  action [ :start ]
end
=end
