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
  action :nothing
end.run_action(:create)