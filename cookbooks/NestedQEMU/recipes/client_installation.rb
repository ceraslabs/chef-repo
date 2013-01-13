class Chef::Recipe
  include InstallationHelpers
end

include_recipe "NestedQEMU::common"

my_databag = data_bag_item(node.name, node.name)

if chef_server?
  ruby_block "set_keys" do
    block do
      node.set["chef_workstation"]["api_client_name"]        = node["output"]["api_client_name"]
      node.set["chef_workstation"]["api_client_key"]         = node["output"]["api_client_key"]
      node.set["chef_workstation"]["validation_client_name"] = node["output"]["validation_client_name"]
      node.set["chef_workstation"]["validation_key"]         = node["output"]["validation_key"]
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
  node.set["chef_workstation"]["api_client_name"]        = chef_server_databag["chef_server"]["api_client_name"]
  node.set["chef_workstation"]["api_client_key"]         = chef_server_databag["chef_server"]["api_client_key"]
  node.set["chef_workstation"]["validation_client_name"] = chef_server_databag["chef_server"]["validation_client_name"]
  node.set["chef_workstation"]["validation_key"]         = chef_server_databag["chef_server"]["validation_key"]
  node.set["chef_workstation"]["chef_server_url"]        = "http://" + chef_server_ip + ":4000"
  node.save
end

include_recipe "chef-workstation"