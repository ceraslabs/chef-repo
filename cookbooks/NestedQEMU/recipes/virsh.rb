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


["qemu", "libvirt-bin"].each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

redirs = []
raw_redirs = node["databags"]["qemu"][node.name]
raw_redirs.each do |redir|
  if redir.start_with?("tcp:80::")
    # since port 80 is privileged port, we setup the iptables rule to forward it to port 8080
    redir = redir.sub("tcp:80::", "tcp:8080::")
    execute "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080" do
      command "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
    end
  end
  redirs << redir
end

nested_hosts = []
node["databags"]["dependencies"]["dependencies"].each do |d|
  nested_hosts << d["from"] if d["to"] == node.name
end

template = nil
cwd = "/home/ubuntu/images"
nested_hosts.each do |hostname|
  image_name = "encrypted_#{hostname}"
  if template.nil?
    execute "rename image #{hostname}" do
      command "mv qemu #{image_name}"
      cwd cwd
      action :nothing
    end.run_action(:run)
    template = image_name
  else
    execute "rename image #{hostname}" do
      command "cp #{template} #{image_name}"
      cwd cwd
      action :nothing
    end.run_action(:run)
  end

  execute "change owner of image #{hostname}" do
    command "chown ubuntu:ubuntu #{image_name}"
    cwd cwd
    action :nothing
  end.run_action(:run)
  
  mount_dir = hostname
  directory "#{cwd}/#{mount_dir}" do
    owner "ubuntu"
    group "ubuntu"
    action :nothing
  end.run_action(:create)

  password = "qemu"
  execute "decrypt qemu image #{hostname}" do
    command "truecrypt --non-interactive #{image_name} #{mount_dir} -p #{password}"
    user "ubuntu"
    group "ubuntu"
    cwd cwd
    action :nothing
  end.run_action(:run)

  # The folder mount_dir should be created as owner of ubuntu, but it doesn't, possibly due to a bug.
  execute "change owner #{mount_dir}" do
    command "chown -R ubuntu:ubuntu #{mount_dir}"
    cwd cwd
    action :nothing
  end.run_action(:run)

  template "/etc/libvirt/qemu/#{hostname}.xml" do
    source "debian.xml.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      :redirs => redirs,
      :hostname => hostname,
      :image => "#{cwd}/#{mount_dir}/debian_hd.img"
    )
    action :nothing
  end.run_action(:create)

  execute "define-inner-instance #{hostname}" do
    command "virsh define /etc/libvirt/qemu/#{hostname}.xml"
    action :nothing
  end.run_action(:run)

  execute "start-inner-instance #{hostname}" do
    command "virsh start #{hostname}"
    action :nothing
  end.run_action(:run)
end