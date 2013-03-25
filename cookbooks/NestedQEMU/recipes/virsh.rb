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

["qemu", "libvirt-bin"].each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

domains = Array.new
`virsh list --all`.each_line do |line|
  tokens = line.split
  domains << tokens[1] if tokens.size > 1 && /[\-\d]/ =~tokens[0]
end

active_domains = Array.new
`virsh list`.each_line do |line|
  tokens = line.split
  active_domains << tokens[1] if tokens.size > 1 && /[\d]/ =~tokens[0]
end


#template = nil
cwd = "/home/ubuntu/images"

directory cwd do
  owner "ubuntu"
  group "ubuntu"
  action :nothing
end.run_action(:create)

my_databag["nested_instances"].each do |nested_instance|
  hostname = nested_instance["host"]
  image_file = nested_instance["image_file"]
  image_url = nested_instance["image_url"]

  if image_file.nil? && image_url.nil?
    raise "Failed get image file. Please make sure either image_file or image_url element is present"
  end

  image_file ||= File.basename(URI::parse(image_url).path)
  image_file = "#{Chef::Config[:file_cache_path]}/#{image_file}" unless Pathname.new(image_file).absolute?

  if !File.exists?(image_file) && image_url.nil?
    railse "Failed get image file. Please make sure image_file is present or provide and URL to download it"
  end

  remote_file image_file do
    source image_url
    action :nothing
  end.run_action(:create_if_missing)

  hosting_image = "#{cwd}/#{hostname}.img"

  execute "copy_image_#{hosting_image}" do
    command "cp #{image_file} #{hosting_image}"
    not_if do
      ::File.exists?(hosting_image)
    end
  end.run_action(:run)

  port_redirs = nested_instance["port_redirs"].map do |r|
    "tcp:#{r["from"]}::#{r["to"]}"
  end

  template "/tmp/#{hostname}.xml" do
    source "libvirt_domain.xml.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      :redirs => port_redirs,
      :hostname => hostname,
      :memory => nested_instance["memory"],
      :image_format => nested_instance["image_format"],
      :image_file_path => hosting_image
    )
    action :nothing
  end.run_action(:create)

  execute "define-inner-instance #{hostname}" do
    command "virsh define /tmp/#{hostname}.xml"
    action :nothing
    not_if do
      domains.include?(hostname)
    end
  end.run_action(:run)

  execute "start-inner-instance #{hostname}" do
    command "virsh start #{hostname}"
    action :nothing
    not_if do
      active_domains.include?(hostname)
    end
  end.run_action(:run)
end