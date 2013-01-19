maintainer       "YOUR_COMPANY_NAME"
maintainer_email "YOUR_EMAIL"
license          "All rights reserved"
description      "Installs/Configures NestedQEMU"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

depends "apt"
depends "chef_handler"
depends "ossec"
depends "kvm"
depends "snort"
depends "apache2"
depends "tomcat"
depends "mysql"
depends "postgresql"
depends "application"
depends "application_java"
depends "database"
depends "chef-server"
depends "pattern-deployer"