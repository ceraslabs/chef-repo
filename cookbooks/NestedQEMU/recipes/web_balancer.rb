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

template "/etc/apache2/mods-available/proxy.conf" do
  source "proxy.conf.erb"
  owner "root"
  group "root"
  mode 0400
  notifies :restart, "service[apache2]"
end

# check the deployment status of each member node, and add them to list only if it is success
this_node = Graph::Node.new(node.name, self)
timeout = this_node["timeout_waiting_members"]
last_tried = Time.now
member_ips = Array.new

get_balancer_members.map do |member_node|

  timeout = timeout - (Time.now - last_tried)
  timeout = [timeout, 10].max
  last_tried = Time.now

  state_type = member_node["update_state"] ? "update_state" : "deploy_state"
  desired_states = %w{ deployed failed }
  if not member_node.wait_for_attr(state_type, :on_values => desired_states, :timeout => timeout)
    raise "Timeout for waiting the deployment of member node #{member_node.name}, please check if that node is deployed successfully"
  end

  if member_node[state_type] == "failed"
    raise "Cannot add member node #{member_node.name} into balancer members since that node failed on deployment"
  end

  ip_type = member_node.private_network? ? "private_ip" : "public_ip"
  if member_node[ip_type]
    member_ips << member_node[ip_type]
  else
    raise "Unexpected missing of #{ip_type} of member node #{member_node.name}"
  end

end

template "/etc/apache2/conf.d/proxy-balancer.conf" do
  source "proxy-balancer.conf.erb"
  owner "root"
  group "root"
  mode 0400
  variables(:member_ips => member_ips)
  notifies :restart, "service[apache2]"
end

service "apache2" do
  action :nothing
end
