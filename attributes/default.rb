default['vsts_build_agent']['binary']['version'] = '2.102.1'

case node['platform_family']
when 'windows'
  default['vsts_build_agent']['binary']['url'] = 'https://github.com/Microsoft/vsts-agent/releases/download/v%s/vsts-agent-win7-x64-%s.zip'
when 'rhel'
  default['vsts_build_agent']['binary']['url'] = 'https://github.com/Microsoft/vsts-agent/releases/download/v%s/vsts-agent-rhel.7.2-x64-%s.tar.gz'
when 'debian'
  default['vsts_build_agent']['binary']['url'] = 'https://github.com/Microsoft/vsts-agent/releases/download/v%s/vsts-agent-ubuntu.14.04-x64-%s.tar.gz'
when 'mac_os_x', 'mac_os_x_server'
  default['vsts_build_agent']['binary']['url'] = 'https://github.com/Microsoft/vsts-agent/releases/download/v%s/vsts-agent-osx.10.11-x64-%s.tar.gz'
end

default['vsts_build_agent']['prerequisites']['osx']['install'] = true
default['vsts_build_agent']['prerequisites']['osx']['openssl']['url'] = 'https://www.openssl.org/source/openssl-1.0.2h.tar.gz'
default['vsts_build_agent']['prerequisites']['osx']['openssl']['version'] = '1.0.2h'

default['vsts_build_agent']['prerequisites']['debian']['install'] = true
default['vsts_build_agent']['prerequisites']['debian']['libicu52']['url'] = 'http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu52_52.1-8ubuntu0.2_amd64.deb'
