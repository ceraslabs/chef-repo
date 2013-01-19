class Chef::Recipe
  include InstallationHelpers
end

include_recipe "NestedQEMU::common"

my_databag = data_bag_item(node.name, node.name)

if chef_server?
  ruby_block "set_keys" do
    block do
      node.set["pattern_deployer"]["chef"]["api_client_name"]        = node["output"]["chef_api_client_name"]
      node.set["pattern_deployer"]["chef"]["api_client_key"]         = node["output"]["chef_api_client_key"]
      node.set["pattern_deployer"]["chef"]["validation_client_name"] = node["output"]["chef_validation_client_name"]
      node.set["pattern_deployer"]["chef"]["validation_key"]         = node["output"]["chef_validation_key"]
      node.save
    end
  end
else
  chef_server_node = my_databag["chef_server"].first
  if my_databag["vpn_connected_nodes"] && my_databag["vpn_connected_nodes"].include?(chef_server_node)
    chef_server_ip = my_databag[chef_server_node]["vpnip"]
  else
    chef_server_ip = my_databag[chef_server_node]["public_ip"]
  end

  chef_server_databag = data_bag_item(chef_server_node, chef_server_node)
  node.set["pattern_deployer"]["chef"]["api_client_name"]        = chef_server_databag["chef_api_client_name"]
  node.set["pattern_deployer"]["chef"]["api_client_key"]         = chef_server_databag["chef_api_client_key"]
  node.set["pattern_deployer"]["chef"]["validation_client_name"] = chef_server_databag["chef_validation_client_name"]
  node.set["pattern_deployer"]["chef"]["validation_key"]         = chef_server_databag["chef_validation_key"]
  node.set["pattern_deployer"]["chef"]["chef_server_url"]        = "http://" + chef_server_ip + ":4000"
  node.save
end

include_recipe "pattern-deployer"
