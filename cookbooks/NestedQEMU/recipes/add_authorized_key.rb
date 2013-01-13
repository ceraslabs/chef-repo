include_recipe "chef_handler"

ssh_key = data_bag_item(node.name, node.name)["ssh_key"]
raise "ssh_key is nil" if ssh_key.nil?

execute "add_authroized_keys" do
  command "echo \"#{ssh_key.strip}\" >> /home/ubuntu/.ssh/authorized_keys"
end