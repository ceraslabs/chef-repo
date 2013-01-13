maintainer       "Guilhem Lettron"
maintainer_email "guilhem.lettron@youscribe.com"
name             "kvm"
license          "Apache 2.0"
description      "Installs/Configures/tuning kvm"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.0"
depends          "apt"
depends          "sysctl"
depends          "modules"

distros = %w(debian ubuntu)

distros.each do |dist|
  supports dist
end
