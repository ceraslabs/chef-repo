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

class Chef::Recipe
  include Graph
end

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

member_ips = get_balancer_members.map do |member_node|
  ip_type = member_node.private_network? ? "private_ip" : "public_ip"
  unless member_node.wait_for_attr(ip_type)
    raise "Failed to get #{ip_type} of member node #{member_node.name}"
  end
  member_node[ip_type]
end

template "/etc/apache2/conf.d/proxy-balancer.conf" do
  source "proxy-balancer.conf.erb"
  owner "root"
  group "root"
  mode 0400
  variables(:vpnips => member_ips)
  notifies :restart, "service[apache2]"
end

template "/etc/apache2/mods-available/proxy.conf" do
  source "proxy.conf.erb"
  owner "root"
  group "root"
  mode 0400
  notifies :restart, "service[apache2]"
end

service "apache2" do
  action :nothing
end
