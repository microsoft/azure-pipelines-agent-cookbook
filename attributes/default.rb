default['azure_pipelines_agent']['binary']['version'] = '2.170.1'

case node['platform_family']
when 'windows'
  default['azure_pipelines_agent']['binary']['url'] = 'https://vstsagentpackage.azureedge.net/agent/%s/vsts-agent-win-x64-%s.zip'
when 'debian', 'rhel'
  default['azure_pipelines_agent']['binary']['url'] = 'https://vstsagentpackage.azureedge.net/agent/%s/vsts-agent-linux-x64-%s.tar.gz'
when 'mac_os_x'
  default['azure_pipelines_agent']['binary']['url'] = 'https://vstsagentpackage.azureedge.net/agent/%s/vsts-agent-osx-x64-%s.tar.gz'
end

default['azure_pipelines_agent']['prerequisites']['debian']['install'] = true
default['azure_pipelines_agent']['prerequisites']['redhat']['install'] = true
