#
# Cookbook Name:: ganglia
# Recipe:: default
#
# Copyright 2011, Heavy Water Software Inc.
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

case node[:platform]
when "ubuntu", "debian"
  template "/usr/sbin/policy-rc.d" do
    mode 0755
    owner "root"
    group "root"
    action :create
  end

  if node[:platform] == "ubuntu" && node[:platform_version] == "11.10"
    # walk around for an issue(https://bugs.launchpad.net/ubuntu/+source/ganglia/+bug/854866)
    apt_repository "add_ganglia_ppa" do
      uri "http://ppa.launchpad.net/mark-mims/ppa/ubuntu"
      distribution node['lsb']['codename']
      components ["main"]
      deb_src true
      keyserver "keyserver.ubuntu.com"
      key "6DF5770B"
    end

    apt_package "ganglia-monitor" do
      version "3.1.7-2ubuntu4"
    end
  else
    package "ganglia-monitor"
  end

  file "/usr/sbin/policy-rc.d" do
    action :delete
  end
when "redhat", "centos", "fedora"
  include_recipe "ganglia::source"

  execute "copy ganglia-monitor init script" do
    command "cp " +
      "/usr/src/ganglia-#{node[:ganglia][:version]}/gmond/gmond.init " +
      "/etc/init.d/ganglia-monitor"
    not_if "test -f /etc/init.d/ganglia-monitor"
  end

  user "ganglia"
end

directory "/etc/ganglia"

case node[:ganglia][:unicast]
when true
  template "/etc/ganglia/gmond.conf" do
    source "gmond_unicast.conf.erb"
    variables( :monitor_localhost => node[:ganglia][:monitor_localhost],
               :mute => node[:ganglia][:mute],
               :deaf => node[:ganglia][:deaf],
               :cluster_name => node[:ganglia][:cluster_name] )
    notifies :restart, "service[ganglia-monitor]"
  end
when false
  template "/etc/ganglia/gmond.conf" do
    source "gmond.conf.erb"
    variables( :cluster_name => node[:ganglia][:cluster_name] )
    notifies :restart, "service[ganglia-monitor]"
  end
end

service "ganglia-monitor" do
  pattern "gmond"
  supports :restart => true
  action [ :enable, :start ]
end
