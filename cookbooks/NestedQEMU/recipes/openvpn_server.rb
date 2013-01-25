#
# Copyright 2013 Marin Litoiu, Hongbin Lu, Mark Shtern, Bradlley Simmons, Mike
# Smit
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "NestedQEMU::common"


my_databag = data_bag_item(node.name, node.name)

# install openvpn server
node["openvpn"]["type"] = "server-bridge"
node["openvpn"]["key"]["size"] = 1024
node["openvpn"]["key_dir"] = "/etc/openvpn/easy-rsa/keys-#{node.name}"
node["openvpn"]["signing_ca_cert"] = "/etc/openvpn/easy-rsa/keys-#{node.name}/ca.crt"
node["openvpn"]["signing_ca_key"] = "/etc/openvpn/easy-rsa/keys-#{node.name}/ca.key"
node["openvpn"]["vpnip"] = my_databag["vpn_server_ip"]
node.save


routes = node['openvpn']['routes']
routes << node['openvpn'] if node['openvpn'].attribute?('push')
node.default['openvpn']['routes'] << routes.flatten!

key_dir = node["openvpn"]["key_dir"]
key_size = node["openvpn"]["key"]["size"]

package "openvpn" do
  action :nothing
end.run_action :install

directory "/etc/openvpn/easy-rsa" do
  owner "root"
  group "root"
  mode 0755
  action :nothing
end.run_action :create

directory key_dir do
  owner "root"
  group "root"
  mode 0700
  recursive true
  action :nothing
end.run_action :create

%w{openssl.cnf pkitool vars Rakefile}.each do |f|
  template "/etc/openvpn/easy-rsa/#{f}" do
    source "#{f}.erb"
    owner "root"
    group "root"
    mode 0755
    action :nothing
  end.run_action :create
end

template "/etc/openvpn/server.up.sh" do
  source "server.up.sh.erb"
  owner "root"
  group "root"
  mode 0755
  action :nothing
end.run_action :create

template "#{key_dir}/openssl.cnf" do
  source "openssl.cnf.erb"
  owner "root"
  group "root"
  mode 0644
  action :nothing
end.run_action :create

file "#{key_dir}/index.txt" do
  owner "root"
  group "root"
  mode 0600
  action :nothing
end.run_action :create

file "#{key_dir}/serial" do
  content "01"
  not_if { ::File.exists?("#{key_dir}/serial") }
  action :nothing
end.run_action :create


ca_certificate = my_databag["server_cert"]["ca_certificate"]
server_certificate = my_databag["server_cert"]["server_certificate"]
server_key = my_databag["server_cert"]["server_key"]
server_private_key = my_databag["server_cert"]["server_private_key"]

template "#{key_dir}/dh#{key_size}.pem" do
  source "crt.erb"
  owner "root"
  group "root"
  mode 0600
  variables( :content => server_private_key )
  action :nothing
end.run_action :create

template node["openvpn"]["signing_ca_cert"] do
  source "crt.erb"
  owner "root"
  group "root"
  mode 0644
  variables( :content => ca_certificate )
  action :nothing
end.run_action :create

template "#{node['openvpn']['key_dir']}/#{node.name}.crt" do
  source "crt.erb"
  owner "root"
  group "root"
  mode 0644
  variables( :content => server_certificate )
  action :nothing
end.run_action :create

template "#{node['openvpn']['key_dir']}/#{node.name}.key" do
  source "crt.erb"
  owner "root"
  group "root"
  mode 0644
  variables( :content => server_key )
  action :nothing
end.run_action :create

ipa = my_databag["vpn_server_ip"].split(".")
irange = "#{ipa[0]}.#{ipa[1]}.#{ipa[2]}.50"
erange = "#{ipa[0]}.#{ipa[1]}.#{ipa[2]}.100"

local_ip = node["ipaddress"]
local_ip = node["ec2"]["local_ipv4"] if node.has_key?("ec2")
template "/etc/openvpn/server.conf" do
  source "server.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :irange => irange, 
    :erange => erange,
    :local_ip => local_ip
  )
  action :nothing
end.run_action :create

service "openvpn" do
  supports :restart => true
end.run_action :restart