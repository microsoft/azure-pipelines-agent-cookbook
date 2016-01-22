name             'vsts_build_agent'
maintainer       'Microsoft'
license          'MIT'
description      'Installs/Configures visualstudio team services build agents'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url       'https://github.com/Microsoft/vsts-build-agent-cookbook' if respond_to?(:source_url)
issues_url       'https://github.com/Microsoft/vsts-build-agent-cookbook/issues' if respond_to?(:issues_url)
version          '0.1.1'


%w( ubuntu debian mac_os_x mac_os_x_server windows ).each do |os|
  supports os
end

suggests 'nodejs'

depends 'runit'
depends 'windows'
