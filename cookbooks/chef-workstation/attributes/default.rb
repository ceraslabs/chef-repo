default["chef_workstation"]["log_level"]              = :info
default["chef_workstation"]["log_location"]           = "STDOUT"
default["chef_workstation"]["conf_dir"]               = "/home/ubuntu/.chef"
default["chef_workstation"]["api_client_name"]        = "client"
default["chef_workstation"]["api_client_key_path"]    = "/home/ubuntu/.chef/client.pem"
default["chef_workstation"]["chef_server_url"]        = "http://localhost:4000"
default["chef_workstation"]["validation_client_name"] = "chef-validator"
default["chef_workstation"]["validation_key_path"]    = "/home/ubuntu/.chef/validation.pem"