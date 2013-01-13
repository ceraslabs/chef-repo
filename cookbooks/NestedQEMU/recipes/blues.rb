include_recipe "chef_handler"


dns_node_name = data_bag_item(node.name, node.name)["dns_node"]
dns_ip = data_bag_item(dns_node_name, dns_node_name)["server_ip"]
template "/etc/dhcp3/dhclient.conf" do
  source "dhclient.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[restart_networking]"
  variables( :dns_ip => dns_ip )
end

execute "restart_networking" do
  command "service networking --full-restart"
  action :nothing
end