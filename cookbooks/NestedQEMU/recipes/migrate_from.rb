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

my_databag = data_bag_item(node.name, node.name)

migration = my_databag["migration"]
raise "Unexpected missing of migration info" if migration.nil?

dest_node_name = migration["destination"]
destination_ip = data_bag_item(dest_node_name, dest_node_name)["public_ip"]

ssh_known_hosts_entry destination_ip do
  action :create
end

domain = migration["domain"]
username = node["current_user"]
migration_cmd = "virsh migrate --live --persistent --verbose --copy-storage-inc #{domain} qemu+ssh://#{username}@#{destination_ip}/system tcp://#{destination_ip}"

ruby_block "vm_migrate" do
  block do
    success = system "su #{username} -c '#{migration_cmd}'"
    raise "Failed to migrate domain '#{domain}' to destination host '#{dest_node_name}'(#{destination_ip})." unless success
  end
end

if migration["load_balancer"]
  lb_node_name = migration["load_balancer"]
  load_balancer_ip = data_bag_item(lb_node_name, lb_node_name)["public_ip"]

  ssh_known_hosts_entry load_balancer_ip do
    action :create
  end

  old_url = my_databag["public_ip"] + ":" + migration["application_port"]
  new_url = destination_ip + ":" + migration["application_port"]
  lb_update_command = "sudo sed -i 's/#{old_url}/#{new_url}/g' /etc/apache2/conf.d/proxy-balancer.conf && sudo service apache2 restart"

  execute "upload_load_balancer" do
    command "ssh ubuntu@#{load_balancer_ip} \"#{lb_update_command}\""
    user username
  end
end