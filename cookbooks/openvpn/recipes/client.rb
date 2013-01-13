package "openvpn" do
  action :nothing
end.run_action :install


my_databag = data_bag_item(node.name, node.name)
my_databag["client_certs"].each do |d|
  key_name = "#{d['from']}-#{d['to']}"
  key_dir = "/etc/openvpn/easy-rsa/keys-#{key_name}"
  signing_ca_cert = "/etc/openvpn/easy-rsa/keys-#{key_name}/ca.crt"

  # wait for server ip of depending nodes
  dep_to = d["to"]
  server_ip = ""
  timeout = my_databag["timeout_waiting_ip"]
  for i in 1 .. timeout
    server_ip = my_databag[dep_to]["public_ip"]

    if !server_ip.nil? && !server_ip.empty?
      break
    elsif i == timeout
      raise "Timeout when waiting the ipaddress of node #{dep_to}"
    end

    sleep 10 #TODO donnot hard code 10
    my_databag = data_bag_item(node.name, node.name)
  end

  directory key_dir do
    owner "root"
    group "root"
    mode 0755
    recursive true
    action :nothing
  end.run_action :create

  template "#{key_dir}/ca.crt" do
    source "crt.erb"
    owner "root"
    group "root"
    mode 0600
    variables(
      :content => d["ca_certificate"]
    )
    action :nothing
  end.run_action :create

  template "#{key_dir}/#{key_name}.crt" do
    source "crt.erb"
    owner "root"
    group "root"
    mode 0600
    variables(
      :content => d["client_certificate"]
    )
    action :nothing
  end.run_action :create

  template "#{key_dir}/#{key_name}.key" do
    source "crt.erb"
    owner "root"
    group "root"
    mode 0600
    variables(
      :content => d["client_key"]
    )
    action :nothing
  end.run_action :create

  template "/etc/openvpn/#{key_name}.conf" do
    source "client.conf.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      :server_ip => server_ip,
      :key_dir => key_dir,
      :key_name => key_name,
      :signing_ca_cert => signing_ca_cert
    )
    action :nothing
  end.run_action :create
end

service "openvpn" do
  supports :restart => true
end.run_action :restart

servers = Array.new
my_databag["client_certs"].each do |d|
  next if d["from"] != node.name
  servers << d["to"]
end

ips = Hash.new
servers.each do |server|
  ip = my_databag[server]["vpnip"]
  ipa = ip.split(".")
  ip = ipa[0] + "." + ipa[1] + "." + ipa[2]
  ips[server] = ip
end

# wait for tap device to come up
vpn_client_ips = Hash.new
timeout = 60
for i in 1 .. timeout
  done = true
  ips.each do |vpn_client, ip|
    ip = `sudo /sbin/ifconfig | grep #{ip} |  grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
    if ip.nil? || ip.empty?
      done = false
    else
      vpn_client_ips[vpn_client] = ip.strip
    end
  end
  break if done

  sleep 1
end

vpn_client_ips.each do |vpn_server, vpnip|
  Chef::Log.info "vpn_server => #{vpn_server}, vpnip => #{vpnip}"
end