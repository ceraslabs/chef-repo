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

environment = {
  "EASY_RSA" => "/etc/openvpn/easy-rsa/2.0",
  "OPENSSL" => "openssl",
  "PKCS11TOOL" => "pkcs11-tool",
  "GREP" => "grep",
  "KEY_CONFIG" => "/etc/openvpn/easy-rsa/2.0/openssl.cnf",
  "KEY_DIR" => "/etc/openvpn/easy-rsa/2.0/keys",
  "PKCS11_MODULE_PATH" => "dummy",
  "PKCS11_PIN" => "dummy",
  "KEY_SIZE" => "1024",
  "CA_EXPIRE" => "3650",
  "KEY_EXPIRE" => "3650",
  "KEY_COUNTRY" => "US",
  "KEY_PROVINCE" => "CA",
  "KEY_CITY" => "SanFrancisco",
  "KEY_ORG" => "Fort-Funston",
  "KEY_EMAIL" => "me@myhost.mydomain"
}

# generate client keys & certs
pairs = data_bag_item(node.name, node.name)["openvpn_client_server_pairs"]
pairs.each do |pair|
  name = pair["from"] + "-" + pair["to"]
  execute "sudo -E /etc/openvpn/easy-rsa/2.0/pkitool #{name}" do
    command "sudo -E /etc/openvpn/easy-rsa/2.0/pkitool #{name}"
    environment (environment)
    not_if { ::File.exists?("/etc/openvpn/easy-rsa/2.0/keys/#{name}.crt") }
  end
end


# generate server keys & certs
openvpn_servers = []
pairs.each do |pair|
  server = pair["to"]
  openvpn_servers << server unless openvpn_servers.include?(server)
end

openvpn_servers.each do |server|
  execute "sudo -E /etc/openvpn/easy-rsa/2.0/pkitool --server #{server}" do
    command "sudo -E /etc/openvpn/easy-rsa/2.0/pkitool --server #{server}"
    environment (environment)
    not_if {File.exists?("/etc/openvpn/easy-rsa/2.0/keys/#{server}.crt")}
  end
end


# save the keys and certs into node attributes
ruby_block "set attributes for dependencies" do
  block do
    node.set["client_certs"] = Array.new
    pairs.each do |pair|
      client_name = pair["from"] + "-" + pair["to"]
      pair["ca_certificate"] = `sudo cat /etc/openvpn/easy-rsa/2.0/keys/ca.crt`
      pair["client_certificate"] = `sudo cat /etc/openvpn/easy-rsa/2.0/keys/#{client_name}.crt`
      pair["client_key"] = `sudo cat /etc/openvpn/easy-rsa/2.0/keys/#{client_name}.key`
      node["client_certs"] << pair
    end

    node.set["server_certs"] = Array.new
    openvpn_servers.each do |server_name|
      server_cert = Hash.new
      server_cert["server_id"] = server_name
      server_cert["ca_certificate"] = `sudo cat /etc/openvpn/easy-rsa/2.0/keys/ca.crt`
      server_cert["server_certificate"] = `sudo cat /etc/openvpn/easy-rsa/2.0/keys/#{server_name}.crt`
      server_cert["server_key"] = `sudo cat /etc/openvpn/easy-rsa/2.0/keys/#{server_name}.key`
      server_cert["server_private_key"] = `sudo cat /etc/openvpn/easy-rsa/2.0/keys/dh1024.pem`
      node["server_certs"] << server_cert
    end

    node.save
  end
end