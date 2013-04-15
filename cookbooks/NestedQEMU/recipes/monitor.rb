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

# wait for ip address of the first node of cluster
recv_node = node.name.sub(/_\d+$/, "_1")
timeout = my_databag["timeout_waiting_ip"]
for i in 1 .. timeout
  if recv_node == node.name
    recv_host = my_databag["public_ip"]
  else
    recv_host = data_bag_item(recv_node, recv_node)["public_ip"]
  end

  break if recv_host

  if i < timeout
    sleep 1
  else
    raise "Failed to get IP of the node #{recv_node}"
  end
end

topology_id = my_databag["topology_id"]
node_short_name = node.name.split("#{topology_id}_node_").last

node.set[:ganglia][:cluster_name] = node_short_name.sub(/_\d+$/, "")
node.set[:ganglia][:host] = recv_host
node.set[:ganglia][:unicast] = true
node.save

include_recipe "ganglia::default"

if node[:recipes].include?("NestedQEMU::virsh")
  metric_collecting_script = "/tmp/collect_domain_metric"
  user = node["current_user"]

  template metric_collecting_script do
    mode 0755
  end

  cron "collect_domain_metric" do
    command "/bin/bash #{metric_collecting_script} 2>&1 >> /var/log/collect_domain_metric.log"
  end
end