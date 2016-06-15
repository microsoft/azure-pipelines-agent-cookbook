default['vsts_build_agent']['binary']['version'] = '2.102.0'

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