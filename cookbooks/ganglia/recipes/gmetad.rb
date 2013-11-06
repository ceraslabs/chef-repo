case node[:platform]
when "ubuntu", "debian"
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

    apt_package "gmetad" do
      version "3.1.7-2ubuntu4"
    end
  else
    package "gmetad"
  end
when "redhat", "centos", "fedora"
  include_recipe "ganglia::source"
  execute "copy gmetad init script" do
    command "cp " +
      "/usr/src/ganglia-#{node[:ganglia][:version]}/gmetad/gmetad.init " +
      "/etc/init.d/gmetad"
    not_if "test -f /etc/init.d/gmetad"
  end
end

directory "/var/lib/ganglia/rrds" do
  owner "nobody"
  recursive true
end

case node[:ganglia][:unicast]
when true
  template "/etc/ganglia/gmetad.conf" do
    source "gmetad.conf.erb"
    variables( :clusters => node[:ganglia][:clusters],
               :gridname => node[:ganglia][:gridname],
               :clients => node[:ganglia][:clients] )
    notifies :restart, "service[gmetad]"
  end
  if node[:recipes].include? "iptables"
    include_recipe "ganglia::iptables"
  end
when false
  ips = search(:node, "*:*").map {|node| node.ipaddress}
  template "/etc/ganglia/gmetad.conf" do
    source "gmetad.conf.erb"
    variables( :clusters => node[:ganglia][:clusters],
               :gridname => node[:ganglia][:gridname] )
    notifies :restart, "service[gmetad]"
  end
end

service "gmetad" do
  supports :restart => true
  action [ :enable, :start ]
end
