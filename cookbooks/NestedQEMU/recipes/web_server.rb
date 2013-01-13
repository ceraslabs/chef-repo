include_recipe "NestedQEMU::common"


tomcat_installed = !`dpkg --get-selections | grep tomcat6`.empty?
unless tomcat_installed
  # install tomcat
  node.set["tomcat"]["port"] = "8080"
  node.set["tomcat"]["ssl_port"] = "8433"
  node.save

  include_recipe "tomcat"
end


my_databag = data_bag_item(node.name, node.name)

database_node = my_databag["database_node"].first
if my_databag["vpn_connected_nodes"] && my_databag["vpn_connected_nodes"].include?(database_node)
  timeout = my_databag["timeout_waiting_vpnip"]
  ip_type = "vpnip"
else
  timeout = my_databag["timeout_waiting_ip"]
  ip_type = "public_ip"
end

database_host = nil
for i in 1 .. timeout
  if database_node == node.name
    database_host = "localhost"
  else
    database_host = my_databag[database_node][ip_type]
  end

  if database_host
    break
  elsif i != timeout
    sleep 1
    my_databag = data_bag_item(node.name, node.name)
  else
    raise "Failed to get ip of database node #{database_node}"
  end
end

db_databag = data_bag_item(database_node, database_node)
app_name = my_databag["war_file"]["name"].sub(/\.war/, "")
application app_name do
  path "/usr/local/#{app_name}"
  owner "tomcat6"
  group "tomcat6"

  java_webapp do
    war_file my_databag["war_file"]["name"]
    database do
      database db_databag["database"]["name"]
      datasource my_databag["war_file"]["datasource"]
      host database_host
      adapter db_databag["database"]["system"]
      username db_databag["database"]["user"]
      password db_databag["database"]["password"]
      max_active 200
      max_idle 30
      max_wait 10000
      if db_databag["database"]["system"] == "mysql"
        driver "com.mysql.jdbc.Driver"
        port "3306"
      elsif db_databag["database"]["system"] == "postgresql"
        driver "org.postgresql.Driver" if db_databag["database"]["system"] == "postgresql"
        port "5432"
      else
        raise "Unexpected dbms #{db_databag["database"]["system"]}"
      end
    end
  end

  tomcat
end


# redirection port 80 to 8080 since port 80 is a privilege port
execute "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080" do
  command "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
end

#service "tomcat6" do
#  supports :restart => true
#  action :start
#end

# find the vpnip of database server
#my_databag = data_bag_item(node.name, node.name)
#database_node = nil
#database_node = my_databag["database"].first

#if database_node
#  mysql_username = my_databag["mysql_username"] || "root"
#  mysql_password = my_databag["mysql_password"] || "root"

#  ip_type = "public_ip"
#  ip_type = "vpnip" if my_databag["vpn_connected_nodes"].include?(database_node)
#  timeout = my_databag["timeout_waiting_vpnip"]
#  mysql_url = nil
#  for i in 1 .. timeout
#    mysql_url = my_databag[database_node][ip_type]
#    if mysql_url
#      break
#    else
#      sleep 1
#      my_databag = data_bag_item(node.name, node.name)
#    end
#  end

#  template "/etc/tomcat6/Catalina/localhost/DatabaseOperations.xml" do
#    source "DatabaseOperations.xml.erb"
#    mode "0644"
#    variables(
#      :mysql_username => mysql_username,
#      :mysql_password => mysql_password,
#      :mysql_server_url => mysql_url
#    )
#  end

#  template "/var/lib/tomcat6/webapps/DatabaseOperations/META-INF/context.xml" do
#    source "DatabaseOperations.xml.erb"
#    mode "0666"
#    variables(
#      :mysql_username => mysql_username,
#      :mysql_password => mysql_password,
#      :mysql_server_url => mysql_url
#    )
#    notifies :restart, "service[tomcat6]"
#  end
#end