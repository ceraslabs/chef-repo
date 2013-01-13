root_user = value_for_platform(
  ["windows"] => { "default" => "Administrator" },
  "default" => "root"
)

root_group = value_for_platform(
  ["openbsd", "freebsd", "mac_os_x", "mac_os_x_server"] => { "default" => "wheel" },
  ["windows"] => { "default" => "Administrators" },
  "default" => "root"
)

directory node["chef_workstation"]["conf_dir"] do
  recursive true
  owner root_user
  group root_group
  mode 0644
end

template node["chef_workstation"]["validation_key_path"] do
  source "validation.pem.erb"
  owner root_user
  group root_group
  mode 0600
end

template node["chef_workstation"]["api_client_key_path"] do
  source "client.pem.erb"
  owner root_user
  group root_group
  mode 0600
end

template "#{node["chef_workstation"]["conf_dir"]}/knife.rb" do
  source "knife.rb.erb"
  owner root_user
  group root_group
  mode 0644
  variables(
    :log_level => :info,
    :log_location => "STDOUT",
    :chef_server_url => node["chef_workstation"]["chef_server_url"],
    :syntax_check_cache_path => File.join(node["chef_workstation"]["conf_dir"], "syntax_check_cache")
  )
end

#ruby_block "load_client_config" do
#  block do
#    Chef::Config.from_file("#{node["chef_workstation"]["conf_dir"]}/knife.rb")
#  end
#end