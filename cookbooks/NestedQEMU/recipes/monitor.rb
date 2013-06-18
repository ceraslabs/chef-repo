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

recv_host = "localhost"
get_monitor_servers.each do |server_node|
  if server_node.name == node.name
    server_ip = "localhost"
  else
    ip_type = server_node.private_network? ? "private_ip" : "public_ip"
    unless server_node.wait_for_attr(ip_type)
      raise "Failed to get #{ip_type} of monitoring server node #{server_node.name}"
    end
    server_ip = server_node[ip_type]
  end

  recv_host = server_ip
end

topology_id = my_databag["topology_id"]
node_short_name = node.name.split("#{topology_id}_node_").last

node.set[:ganglia][:cluster_name] = node_short_name.sub(/_\d+$/, "")
node.set[:ganglia][:host] = recv_host
node.set[:ganglia][:deaf] = "yes"
node.set[:ganglia][:unicast] = true
node.save

include_recipe "ganglia::default"
