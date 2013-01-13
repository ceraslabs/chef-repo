# install apt
include_recipe "apt"

# install exception handler
include_recipe "chef_handler"

#databag = data_bag_item(node.name, node.name).to_hash
#if databag.has_key?("topology_id")
#  node.set["topology_id"] = databag["topology_id"]
#  node.save
#end