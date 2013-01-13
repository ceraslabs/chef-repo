include_recipe "NestedQEMU::common"


my_databag = data_bag_item(node.name, node.name)
clients_ips = Array.new
my_databag["hids_clients"].each do |client|
  num_of_tries = 10
  for i in 1 .. num_of_tries
    client_ip = my_databag["server_ip"]

    if client_ip
      clients_ips << client_ip if not client_ips.include?(client_ip)
      break
    else
      sleep 30
      my_databag = data_bag_item(node.name, node.name)
    end
  end
end

template "/var/ossec/etc/ossec.conf" do
  source "ossec.conf.erb"
  user "root"
  group "ossec"
  mode 0440
  variables( :ips => clients_ips )
  notifies :restart, "service[ossec]"
end

clients_ips.each do |ip|
  ruby_block "register host #{ip}" do
    block do
      client = "ubuntu@#{ip}"
      output = `/var/ossec/agentless/register_host.sh list #{client}`
      if output.nil? || output.empty?
        system "/var/ossec/agentless/register_host.sh add #{client} NOPASS"
      end
    end
  end
end

service "ossec" do
  supports :status => true, :restart => true
  action :start
end