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

directory = "/root/.ssh"
private_key_file = "#{directory}/id_rsa"
public_key_file = "#{directory}/id_rsa.pub"
file private_key_file do
  action :delete
end

file public_key_file do
  action :delete
end

directory directory do
  action :create
end

execute "generate_key" do
  command "ssh-keygen -q -t rsa -N \"\" -f #{private_key_file}"
end

ruby_block "save_key" do
  block do
    node["ssh_key"] = `cat #{public_key_file}`
    node.save
  end
end