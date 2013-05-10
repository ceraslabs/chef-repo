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

source_node_name = migration["source"]
user_public_key = data_bag_item(source_node_name, source_node_name)["user_public_key"]
authorized_keys = [user_public_key]

user_account node["current_user"] do
  ssh_keys authorized_keys
  action :create
end

nested_nodes_infos = my_databag["nested_nodes_infos"] || Array.new
domain_name = migration["domain"]
domain_info = nested_nodes_infos.find{ |nni| nni["host"] == domain_name }
if domain_info.nil?
  source_node = migration["source"]
  domain_info = data_bag_item(source_node, source_node)["nested_nodes_infos"].find{ |nni| nni["host"] == domain_name }
end

image_file = domain_info["image_file"]
image_url = domain_info["image_url"]
if image_file.nil? && image_url.nil?
  raise "Failed get image file. Please make sure either image_file or image_url element is present"
end

image_file ||= File.basename(URI::parse(image_url).path)
image_file = "#{Chef::Config[:file_cache_path]}/#{image_file}" unless Pathname.new(image_file).absolute?
if !File.exists?(image_file) && image_url.nil?
  railse "Failed get image file. Please make sure image_file is present or provide and URL to download it"
end

remote_file image_file do
  source image_url
  action :create_if_missing
end

user_home = "#{node["user"]["home_root"]}/#{node["current_user"]}"
hosting_image = "#{user_home}/images/#{domain_name}.img"

execute "copy_image_#{hosting_image}" do
  command "cp #{image_file} #{hosting_image}"
  not_if do
    ::File.exists?(hosting_image)
  end
end