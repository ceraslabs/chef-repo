include_recipe "NestedQEMU::common"


server_private_ip = node["databags"]["blues"]["server_private_ip"]
template "/etc/bind/named.conf.local" do
  source "named.conf.local.erb"
  owner "root"
  group "bind"
  mode 0644
  variables({ :blue_ip => server_private_ip })
end

clients = []
node["databags"]["dns"]["clients"].each do |client|
  num_of_tries = 10
  server_ip = nil
  for i in 1 .. num_of_tries
    databag = data_bag_item(client, client)
    server_ip = databag["server_ip"]
    break if !server_ip.nil?

    sleep 30
  end

  if !server_ip.nil?
    server_ip = server_ip.strip
    client = {}
    client["ip"] = server_ip
    ipa = server_ip.split(".")
    client["name"] = "client-" + ipa[0] + "-" + ipa[1] + "-" + ipa[2] + "-" + ipa[3]
    clients.push(client)
  end
end

template "/etc/bind/db.p-cloud-p.com" do
  source "db.p-cloud-p.com.erb"
  owner "root"
  group "bind"
  mode 0644
  variables({ :clients => clients, :blue_ip => node["databags"]["blues"]["server_ip"] })
  notifies :restart, "service[bind9]"
end

service "bind9" do
  supports :restart => true
  action :nothing
end