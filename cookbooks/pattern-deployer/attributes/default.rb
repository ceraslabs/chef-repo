default["pattern_deployer"]["user"] = "pattern-deployer"
default["pattern_deployer"]["group"] = "pattern-deployer"
default["pattern_deployer"]["service_name"] = "pattern-deployer"
default["pattern_deployer"]["deploy_to"] = "/usr/local/pattern-deployer"

default["pattern_deployer"]["database"]["system"] = "mysql"
default["pattern_deployer"]["database"]["name"] = "project_production"
default["pattern_deployer"]["database"]["username"] = "pattern-deployer"
default["pattern_deployer"]["database"]["password"] = "pattern-deployer"
default["pattern_deployer"]["database"]["adapter"] = "mysql2"

default["pattern_deployer"]["chef"]["log_level"]              = :info
default["pattern_deployer"]["chef"]["log_location"]           = "STDOUT"
default["pattern_deployer"]["chef"]["conf_dir"]               = "#{node["pattern_deployer"]["deploy_to"]}/current/chef-repo/.chef"
default["pattern_deployer"]["chef"]["api_client_name"]        = "client"
default["pattern_deployer"]["chef"]["api_client_key_path"]    = "#{node["pattern_deployer"]["chef"]["conf_dir"]}/client.pem"
default["pattern_deployer"]["chef"]["chef_server_url"]        = "http://localhost:4000"
default["pattern_deployer"]["chef"]["validation_client_name"] = "chef-validator"
default["pattern_deployer"]["chef"]["validation_key_path"]    = "#{node["pattern_deployer"]["chef"]["conf_dir"] }/validation.pem"