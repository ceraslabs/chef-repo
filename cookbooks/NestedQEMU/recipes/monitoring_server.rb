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

my_databag = data_bag_item(node.name, node.name)

timeout = my_databag["timeout_waiting_ip"]
topology_id = my_databag["topology_id"]

clusters = Hash.new
my_databag["monitor_clients"].each do |client_node_name|
  # wait for ip address of client
  for i in 1 .. timeout
    if client_node_name == node.name
      client_ip = "localhost"
    else
      my_databag = data_bag_item(node.name, node.name)
      client_ip = my_databag[client_node_name]["public_ip"]
    end

    break if client_ip

    if i < timeout
      sleep 1
    else
      raise "Failed to get ip of node #{client_node_name}"
    end
  end

  client_node_short_name = client_node_name.split("#{topology_id}_node_").last
  cluster_name = client_node_short_name.sub(/_\d+$/, "")
  clusters[cluster_name] = client_ip if client_node_short_name.end_with?("_1")
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
