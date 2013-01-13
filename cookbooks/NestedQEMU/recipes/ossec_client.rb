include_recipe "chef_handler"

template "/tmp/id_rsa.pub" do
  source "id_rsa.pub.erb"
end

execute "append authorized_keys" do
  command "cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys"
end