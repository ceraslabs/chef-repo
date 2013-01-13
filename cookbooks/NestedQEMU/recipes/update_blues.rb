include_recipe "NestedQEMU::common"


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
    ipa = server_ip.split(".")
    clients << "client-" + ipa[0] + "-" + ipa[1] + "-" + ipa[2] + "-" + ipa[3]
  end
end

template "/etc/lbnamed.config" do
  source "lbnamed.config.erb"
  owner "root"
  group "root"
  mode 0644
  variables( :clients => clients )
  #notifies :run, "execute[kill-old-lbnamed-process]"
  #notifies :delete, "file[/tmp/lbnamed.log]"
  #notifies :run, "execute[run-lbnamed]"
end


execute "kill-old-lbnamed-process" do
  command "kill -9 `cat /var/run/lbnamed.pid`"
  only_if do
    File.exists?("/var/run/lbnamed.pid")
  end
  action :run
end

file "/tmp/lbnamed.log" do
  only_if do
    File.exists?("/tmp/lbnamed.log")
  end
  action :delete
end

execute "run-lbnamed" do
  command "/home/mark/DNS/lbnamed-2.3.2/lbnamed -h #{node['ec2']['local_ipv4']} -l /tmp/lbnamed.log -d"
  cwd "/home/mark/DNS/lbnamed-2.3.2"
  action :run
end

