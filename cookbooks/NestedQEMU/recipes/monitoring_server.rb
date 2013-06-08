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

my_databag = data_bag_item(node.name, node.name)

timeout = my_databag["timeout_waiting_ip"]
topology_id = my_databag["topology_id"]

clusters = Hash.new
get_monitor_clients.each do |client_node|
  if client_node.name == node.name
    client_ip = "localhost"
  else
    ip_type = client_node.private_network? ? "private_ip" : "public_ip"
    unless client_node.wait_for_attr(ip_type)
      raise "Failed to get #{ip_type} of monitor client node #{client_node.name}"
    end
    client_ip = client_node[ip_type]
  end

  clusters[client_node.cluster_name] = client_ip if client_node.first_node_of_cluster?
end

node.set[:ganglia][:unicast] = true
node.set[:ganglia][:clusters] = clusters
node.set[:ganglia][:mute] = "yes"
node.set[:ganglia][:deaf] = "yes"
node.set[:ganglia][:gridname] = topology_id
node.save

include_recipe "ganglia::default"
include_recipe "ganglia::gmetad"
include_recipe "ganglia::web"
