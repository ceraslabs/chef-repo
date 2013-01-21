include Chef::Mixin::LanguageIncludeRecipe

action :before_compile do

  node.set[:passenger][:production][:service_name] = @new_resource.service_name
  node.save

  include_recipe "passenger::daemon"

end

action :before_deploy do

  new_resource = @new_resource
  nginx_path = node[:passenger][:production][:path]

  template "#{nginx_path}/conf/sites.d/#{new_resource.application.name}.conf" do
    source "app.config.erb"
    cookbook "application_ruby"
    mode "0644"
    variables(
      :docroot => "#{new_resource.application.path}/current/public"
    )
  end

end

action :before_migrate do
end

action :before_symlink do
end

action :before_restart do
end

action :after_restart do
end
