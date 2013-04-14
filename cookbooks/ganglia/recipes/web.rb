directory "/etc/ganglia-webfrontend"

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

    apt_package "ganglia-webfrontend" do
      version "3.1.7-2ubuntu4"
    end
  else
    package "ganglia-webfrontend"
  end

  link "/etc/apache2/sites-enabled/ganglia" do
    to "/etc/ganglia-webfrontend/apache.conf"
    notifies :restart, "service[apache2]"
  end

when "redhat", "centos", "fedora"
  package "httpd"
  package "php"
  include_recipe "ganglia::source"
  include_recipe "ganglia::gmetad"

  execute "copy web directory" do
    command "cp -r web /var/www/html/ganglia"
    creates "/var/www/html/ganglia"
    cwd "/usr/src/ganglia-#{node[:ganglia][:version]}"
  end
end

service "apache2" do
  service_name "httpd" if platform?( "redhat", "centos", "fedora" )
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
