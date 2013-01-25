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


def get_vpnip(node_name, neighbour)
  vpnip = nil
  timeout = node["databags"]["policy"]["timeout_for_waiting_vpnips"]
  for i in 1 .. timeout
    databag = data_bag_item(node_name, node_name)
    vpnip = databag["vpn_server_ip"]
    vpn_client_ips = databag["vpn_client_ips"] if vpnip.nil?
    vpnip = vpn_client_ips[neighbour] if !vpn_client_ips.nil?
    break if !vpnip.nil?

    sleep 1
  end
  raise "Failed to get vpnip of node #{node_name}: timeout" if vpnip.nil?
  return vpnip
end

def get_tap_device(node_name)
  ip = get_vpnip(node_name, node.name)
  ipa = ip.split(".")
  ip_prefix = "#{ipa[0]}.#{ipa[1]}.#{ipa[2]}."

  ifconfig = `ifconfig`
  lines = ifconfig.split("\n")
  tap_device = ""
  lines.each do |line|
    tap_device = line.split(" ")[0] if line.start_with?("tap")
    break if !line.index(ip_prefix).nil?
  end

  return tap_device
end

my_node = node.name
is_vpn_server = !data_bag_item(my_node, my_node)["vpn_server_ip"].nil?

if is_vpn_server
  my_pairs = {}
  databag = node["databags"]["snort"]
  databag["snort_pairs"].each { |pair|
    snort_node = pair["snort_node"]
    if pair["pair1"] == node.name then
      my_pairs[snort_node] = pair["pair2"]
    elsif pair["pair2"] == node.name then
      my_pairs[snort_node] = pair["pair1"]
    end
  }


  my_pairs.each do |snort, my_pair|
    tap_device = get_tap_device(snort)
    my_pair_ip = get_vpnip(my_pair, snort)
    ipa = my_pair_ip.split(".")
    nip = ipa[0] + "." + ipa[1] + "." + ipa[2] + ".0"

    system "sudo route add -net #{nip}/24 dev #{tap_device}"
  end
end