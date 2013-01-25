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

databag = data_bag_item(node.name, node.name)
target_vm = databag["vm_to_migrate"]
destination_url = databag["migrate_to"]

result = `echo /etc/ssh/ssh_config | grep "StrictHostKeyChecking no"`
if result.empty?
  execute "disable_host_key_verification" do
    command "echo \"StrictHostKeyChecking no\" >> /etc/ssh/ssh_config"
  end
end

execute "vm_migrate" do
  #command "virsh migrate --live --persistent --undefinesource --copy-storage-inc --verbose #{target_vm} qemu+ssh://ubuntu@#{destination_url}/system"
  command "virsh migrate --live --persistent --verbose --copy-storage-inc #{target_vm} qemu+ssh://ubuntu@#{destination_url}/system"
end