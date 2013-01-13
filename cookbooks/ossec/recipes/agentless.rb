template "/tmp/id_ras.pub" do
  source "id_ras.pub.erb"
end

execute "append authorized_keys" do
  command "cat /tmp/id_ras.pub >> /home/ubuntu/.ssh/authorized_keys"
end
