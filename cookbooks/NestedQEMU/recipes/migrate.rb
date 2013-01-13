include_recipe "chef_handler"

databag = data_bag_item(node.name, node.name)
target_vm = databag["vm_to_migrate"]
destination_url = databag["migrate_to"]

result = `echo /etc/ssh/ssh_config | grep "StrictHostKeyChecking no"`
if result.empty?
  execute "disable_host_key_verification" do
    command "echo \"StrictHostKeyChecking no\" >> /etc/ssh/ssh_config"
  end
end

execute "vm_migrate" do
  #command "virsh migrate --live --persistent --undefinesource --copy-storage-inc --verbose #{target_vm} qemu+ssh://ubuntu@#{destination_url}/system"
  command "virsh migrate --live --persistent --verbose --copy-storage-inc #{target_vm} qemu+ssh://ubuntu@#{destination_url}/system"
end
