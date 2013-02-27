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

node.set['build_essential']['compiletime'] = true
node.save

include_recipe "build-essential"

node.set["chef_server"]["webui_enabled"] = true
node.save

include_recipe "chef-server::rubygems-install"

new_client_name = "workstation"
new_client_key = "/etc/chef/#{new_client_name}.pem"
server_url = "http://localhost:4000"

execute "create_admin_client" do
  command "knife configure -i -y --defaults -u #{new_client_name} -k #{new_client_key} -s #{server_url} -r ''"
  not_if do
    File.exists?(new_client_key)
  end
end

ruby_block "save_admin_client_info" do
  block do
    node.set["output"]["chef_api_client_name"] = new_client_name
    node.set["output"]["chef_api_client_key"] = `sudo cat #{new_client_key}`
    node.set["output"]["chef_validation_client_name"] = node["chef_server"]["validation_client_name"]
    node.set["output"]["chef_validation_key"] = `sudo cat /etc/chef/validation.pem`
    node.save
  end
end