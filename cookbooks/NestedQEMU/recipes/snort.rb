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
include_recipe "snort"


package "bridge-utils" do
  action :nothing
end.run_action(:install)

my_databag = data_bag_item(node.name, node.name)
all_pairs = Array.new
my_databag["snort_pairs"].each do |pair|
  all_pairs << pair["pair1"] if !all_pairs.include?(pair["pair1"])
  all_pairs << pair["pair2"] if !all_pairs.include?(pair["pair2"])
end

is_vpn_client = my_databag["vpn_server_ip"].nil?
if is_vpn_client
  execute "brctl addbr br0"
    command "brctl addbr br0"
  end

  for i in 0 .. all_pairs.length - 1
    execute "brctl addif br0 tap#{i}"
      command "brctl addif br0 tap#{i}"
    end
  end

  execute "ifconfig br0 up"
    command "ifconfig br0 up"
  end
end