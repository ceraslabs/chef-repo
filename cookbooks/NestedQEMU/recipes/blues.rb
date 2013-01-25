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
include_recipe "chef_handler"


dns_node_name = data_bag_item(node.name, node.name)["dns_node"]
dns_ip = data_bag_item(dns_node_name, dns_node_name)["server_ip"]
template "/etc/dhcp3/dhclient.conf" do
  source "dhclient.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[restart_networking]"
  variables( :dns_ip => dns_ip )
end

execute "restart_networking" do
  command "service networking --full-restart"
  action :nothing
end