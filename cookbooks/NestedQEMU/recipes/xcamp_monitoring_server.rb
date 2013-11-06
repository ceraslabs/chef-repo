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

clients = Hash.new
get_monitor_clients.each do |client_node|
  if client_node.name == node.name
    client_ip = "127.0.0.1"
  else
    ip_type = client_node.private_network? ? "private_ip" : "public_ip"
    unless client_node.wait_for_attr(ip_type)
      raise "Failed to get #{ip_type} of monitoring server node #{client_node.name}"
    end
    client_ip = client_node[ip_type]
  end

  client_name = get_node_shortname(client_node.name)
  clients[client_name] = client_ip
end

node.set[:ganglia][:unicast] = true
node.set[:ganglia][:gridname] = get_topology_name
node.set[:ganglia][:clients] = clients
node.save

include_recipe "ganglia::default"
include_recipe "ganglia::gmetad"
include_recipe "ganglia::web"
