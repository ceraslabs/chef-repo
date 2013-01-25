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
# install common packages
include_recipe "NestedQEMU::common"

# install apache
include_recipe "apache2"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_ajp"
include_recipe "apache2::mod_proxy_balancer"
include_recipe "apache2::mod_proxy_connect"
include_recipe "apache2::mod_proxy_http"


my_databag = data_bag_item(node.name, node.name)

member_ips = Array.new
my_databag["balancer_members"].each do |member|
  if my_databag["vpn_connected_nodes"].include?(member)
    ip_type = "vpnip"
    timeout = my_databag["timeout_waiting_vpnip"]
  else
    ip_type = "public_ip"
    timeout = my_databag["timeout_waiting_ip"]
  end

  member_ip = nil
  for i in 1 .. timeout
    if my_databag[member].has_key?(ip_type)
      member_ip = my_databag[member][ip_type] #TODO
      break
    else
      sleep 5
      my_databag = data_bag_item(node.name, node.name)
    end
  end

  member_ips << member_ip if member_ip
end


#member_ips = []
#relationships = node["databags"]["relationships"]["relationships"]
#relationships.each do |r|
#  next if r["from"] != node.name || r["type"] != "load_balancing"
#  member_node = r["to"]
#  dependencies = node["databags"]["dependencies"]["dependencies"]
#  dependencies.each do |d|
#    member_node = d["to"] if d["from"] == member_node && d["type"] == "nested"
#  end

#  snort_node = nil
#  node["databags"]["snort"]["snort_pairs"].each do |pair|
#    snort_node = pair["snort_node"] if (pair["pair1"] == node.name && pair["pair2"] == member_node) || (pair["pair2"] == node.name && pair["pair1"] == member_node)
#  end

#  timeout = node["databags"]["policy"]["timeout_for_waiting_vpnips"]
#  for i in 1 .. timeout
#    databag = data_bag_item(member_node, member_node)
#    member_ip = databag["vpn_server_ip"]
#    vpn_client_ips = databag["vpn_client_ips"] if member_ip.nil?
#    member_ip = vpn_client_ips[snort_node] if !vpn_client_ips.nil?
#    if !member_ip.nil?
#      member_ips << member_ip
#      break
#    end

#    sleep 1
#  end
#end

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
  notifies :restart, "service[apache2]"
end

service "apache2" do
  supports :status => true, :restart => true
end