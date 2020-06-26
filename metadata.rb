name             'vsts_agent'
maintainer       'Microsoft'
maintainer_email 'eahanl@microsoft.com'
license          'MIT'
description      'Installs/Configures visualstudio team services build agents'
source_url       'https://github.com/Microsoft/azure-pipelines-agent-cookbook'
issues_url       'https://github.com/Microsoft/azure-pipelines-agent-cookbook/issues'
chef_version     '>= 14'
version          '3.2.0'

%w(ubuntu debian redhat centos mac_os_x windows).each do |operating_system|
  supports operating_system
end

depends 'windows'
depends 'ark'
depends 'seven_zip', '>= 2.0.0'
