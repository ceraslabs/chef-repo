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