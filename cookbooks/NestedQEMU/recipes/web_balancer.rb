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


# install apache2
list = `dpkg --get-selections | grep apache2`
if list.empty?
  include_recipe "NestedQEMU::common"
  include_recipe "apache2"
  include_recipe "apache2::mod_proxy"
  include_recipe "apache2::mod_proxy_ajp"
  include_recipe "apache2::mod_proxy_balancer"
  include_recipe "apache2::mod_proxy_connect"
  include_recipe "apache2::mod_proxy_http"
else
  include_recipe "chef_handler"

  execute "/usr/sbin/a2enmod proxy*" do
    command "/usr/sbin/a2enmod proxy*"
  end
end

my_databag = data_bag_item(node.name, node.name)
member_ips = Array.new
my_databag["balancer_members"].each do |member_node|
  if my_databag["vpn_connected_nodes"] && my_databag["vpn_connected_nodes"].include?(member_node)
    timeout = my_databag["timeout_waiting_vpnip"]
    ip_type = "vpnip"
  else
    timeout = my_databag["timeout_waiting_ip"]
    ip_type = "public_ip"
  end

  for i in 1 .. timeout
    if member_node == node.name
      member_ip = "127.0.0.1"
    else
      member_ip = my_databag[member_node][ip_type]
    end

    if member_ip
      member_ips << member_ip
      break
    elsif i != timeout
      sleep 1
      my_databag = data_bag_item(node.name, node.name)
    else
      raise "Failed to get ip of node #{member_node}"
    end
  end
end

template "/etc/apache2/conf.d/proxy-balancer.conf" do
  source "proxy-balancer.conf.erb"
  owner "root"
  group "root"
  mode 0400
  variables(:vpnips => member_ips)
end

template "/etc/apache2/mods-available/proxy.conf" do
  source "proxy.conf.erb"
  owner "root"
  group "root"
  mode 0400
end

service "apache2" do
  action :restart
end