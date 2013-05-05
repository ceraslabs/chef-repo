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


tomcat_installed = !`dpkg --get-selections | grep tomcat6`.empty?
unless tomcat_installed
  # install tomcat
  node.set["tomcat"]["port"] = "8080"
  node.set["tomcat"]["ssl_port"] = "8433"
  node.save

  include_recipe "tomcat"
end


my_databag = data_bag_item(node.name, node.name)

app_name = my_databag["war_file"]["name"].sub(/\.war/, "")
if my_databag["database_node"] && my_databag["database_node"].first
  # Setup database connection
  database_node = my_databag["database_node"].first

  if my_databag["vpn_connected_nodes"] && my_databag["vpn_connected_nodes"].include?(database_node)
    timeout = my_databag["timeout_waiting_vpnip"]
    ip_type = "vpnip"
  else
    timeout = my_databag["timeout_waiting_ip"]
    ip_type = "public_ip"
  end

  # pick up the IP address of database
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
  application app_name do
    path "/usr/local/#{app_name}"
    owner "tomcat6"
    group "tomcat6"

    java_webapp do
      database do
        database db_databag["database"]["name"]
        datasource my_databag["war_file"]["datasource"]
        host database_host
        adapter db_databag["database"]["system"]
        username db_databag["database"]["user"]
        password db_databag["database"]["password"]
        port db_databag["database"]["port"]
        max_active 200
        max_idle 30
        max_wait 10000
        if db_databag["database"]["system"] == "mysql"
          driver "com.mysql.jdbc.Driver"
        elsif db_databag["database"]["system"] == "postgresql"
          driver "org.postgresql.Driver" if db_databag["database"]["system"] == "postgresql"
        else
          raise "Unexpected dbms #{db_databag["database"]["system"]}"
        end
      end
    end

    tomcat
  end
else
  # No need to setup database connection
  application app_name do
    path "/usr/local/#{app_name}"
    owner "tomcat6"
    group "tomcat6"
    java_webapp
    tomcat
  end
end


# redirection port 80 to 8080 since port 80 is a privilege port
execute "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080" do
  command "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
end