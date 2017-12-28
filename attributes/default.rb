default['vsts_agent']['binary']['version'] = '2.126.0'

case node['platform_family']
when 'windows'
  default['vsts_agent']['binary']['url'] = 'https://vstsagentpackage.azureedge.net/agent/%s/vsts-agent-win-x64-%s.zip'
when 'debian', 'rhel'
  default['vsts_agent']['binary']['url'] = 'https://vstsagentpackage.azureedge.net/agent/%s/vsts-agent-linux-x64-%s.tar.gz'
when 'mac_os_x', 'mac_os_x_server'
  default['vsts_agent']['binary']['url'] = 'https://vstsagentpackage.azureedge.net/agent/%s/vsts-agent-osx-x64-%s.tar.gz'
end

# applies for debian based distros: ubuntu, debian etc...
default['vsts_agent']['prerequisites']['debian']['install'] = true

# applies for redhat based distros: redhat, centos etc...
default['vsts_agent']['prerequisites']['redhat']['install'] = true
