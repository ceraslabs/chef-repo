#
# Cookbook Name:: openvpn
# Recipe:: users
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

databag = data_bag_item("openvpn", "openvpn")
dependencies = databag["dependencies"]
dependencies.each { |d|
  next if d["to"] != node.name

  client_name = d["from"]
  key_name = "#{d['from']}-#{d['to']}"

  execute "generate-openvpn-#{key_name}" do
    command "./pkitool #{key_name}"
    cwd "/etc/openvpn/easy-rsa"
    environment(
      'EASY_RSA' => '/etc/openvpn/easy-rsa',
      'KEY_CONFIG' => '/etc/openvpn/easy-rsa/openssl.cnf',
      'KEY_DIR' => node["openvpn"]["key_dir"],
      'CA_EXPIRE' => node["openvpn"]["key"]["ca_expire"].to_s,
      'KEY_EXPIRE' => node["openvpn"]["key"]["expire"].to_s,
      'KEY_SIZE' => node["openvpn"]["key"]["size"].to_s,
      'KEY_COUNTRY' => node["openvpn"]["key"]["country"],
      'KEY_PROVINCE' => node["openvpn"]["key"]["province"],
      'KEY_CITY' => node["openvpn"]["key"]["city"],
      'KEY_ORG' => node["openvpn"]["key"]["org"],
      'KEY_EMAIL' => node["openvpn"]["key"]["email"]
    )
    not_if { ::File.exists?("#{node["openvpn"]["key_dir"]}/#{key_name}.crt") }
  end

  ruby_block "set_attributes_#{key_name}" do
    block do
      client = {}
      client["ca_certificate"] = `cat #{node["openvpn"]["key_dir"]}/ca.crt`
      client["client_certificate"] = `cat #{node["openvpn"]["key_dir"]}/#{key_name}.crt`
      client["client_key"] = `cat #{node["openvpn"]["key_dir"]}/#{key_name}.key`
      clients = {}
      clients["#{client_name}"] = client
      node["openvpn"]["clients"] = clients
      node.save
    end
  end
}

ruby_block "set server_ip and ca_certificate" do
  block do
    node["openvpn"]["server_ip"] = node["ec2"]["public_ipv4"]    
    node.save
  end
end