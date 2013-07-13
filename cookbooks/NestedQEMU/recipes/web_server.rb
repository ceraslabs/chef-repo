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
war_file_name = my_databag["war_file"]["name"]
app_name = war_file_name.sub(/\.war/, "")

db_node = get_database_node.first if get_database_node
if db_node
  # Setup database connection
  ip_type = db_node.private_network? ? "private_ip" : "public_ip"
  unless db_node.wait_for_attr(ip_type)
    raise "Failed to get #{ip_type} of database node #{db_node.name}"
  end

  file_source = get_file_source(war_file_name)

  application app_name do
    path "/usr/local/#{app_name}"
    owner "tomcat6"
    group "tomcat6"
    source file_source

    java_webapp do
      database do
        database   db_node["database"]["name"]
        datasource my_databag["war_file"]["datasource"]
        host       db_node[ip_type]
        adapter    db_node["database"]["system"]
        username   db_node["database"]["user"]
        password   db_node["database"]["password"]
        port       db_node["database"]["port"]
        max_active 200
        max_idle   30
        max_wait   10000
        if db_node["database"]["system"] == "mysql"
          driver "com.mysql.jdbc.Driver"
        elsif db_node["database"]["system"] == "postgresql"
          driver "org.postgresql.Driver" if db_node["database"]["system"] == "postgresql"
        else
          raise "Unexpected dbms #{db_node["database"]["system"]}"
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