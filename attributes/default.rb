default['vsts_build_agent']['xplat']['package_name'] = 'vsoagent-installer'
default['vsts_build_agent']['xplat']['package_version'] = 'latest'
default['vsts_build_agent']['xplat']['skip_vsoagent_installer'] = false

default['vsts_build_agent']['binary']['windows'] = 'tbd'
default['vsts_build_agent']['binary']['ubuntu'] = 'https://github.com/Microsoft/vsts-agent/releases/download/v2.101.1/vsts-agent-ubuntu.14.04-x64-2.101.1.tar.gz'
default['vsts_build_agent']['binary']['rhel'] = 'https://github.com/Microsoft/vsts-agent/releases/download/v2.101.1/vsts-agent-rhel.7.2-x64-2.101.1.tar.gz'
default['vsts_build_agent']['binary']['osx'] = 'https://github.com/Microsoft/vsts-agent/releases/download/v2.101.1/vsts-agent-osx.10.11-x64-2.101.1.tar.gz'