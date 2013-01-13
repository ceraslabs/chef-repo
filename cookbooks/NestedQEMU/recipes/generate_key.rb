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
