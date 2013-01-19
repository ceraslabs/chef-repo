include Chef::Resource::ApplicationBase

attribute :service_name, :kind_of => [String, NilClass], :default => "passenger_demo_app"
