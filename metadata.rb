name             'vsts_build_agent'
maintainer       'Microsoft'
license          'MIT'
description      'Installs/Configures visualstudio team services build agents'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w( ubuntu debian mac_os_x mac_os_x_server windows ).each do |os|
  supports os
end

suggests 'nodejs'

depends 'runit'
depends 'windows'
