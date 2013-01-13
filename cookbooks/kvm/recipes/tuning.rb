include_recipe "kvm::default"

include_recipe "sysctl"

include_recipe "modules"

if node[:cpu]["0"][:flags].include?("ept")
  sysctl "vm.swappiness" do
    value "0"
  end
end

modules "vhost_net"
