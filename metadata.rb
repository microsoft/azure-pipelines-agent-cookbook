name             'vsts_agent'
maintainer       'Microsoft'
maintainer_email 'dmivanov@microsoft.com'
license          'MIT'
description      'Installs/Configures visualstudio team services build agents'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url       'https://github.com/Microsoft/vsts-agent-cookbook' if respond_to?(:source_url)
issues_url       'https://github.com/Microsoft/vsts-agent-cookbook/issues' if respond_to?(:issues_url)
chef_version     '>= 12.4' if respond_to?(:chef_version)
version          '2.0.2'

%w(ubuntu debian redhat centos mac_os_x windows).each do |operating_system|
  supports operating_system
end

depends 'windows'
depends 'ark'
depends 'seven_zip', '~> 2.0.0'
