default['nodejs']['version'] = '4.2.3'
default['nodejs']['source']['checksum'] = nil
default['nodejs']['binary']['checksum']['linux_x64'] = nil
default['nodejs']['binary']['checksum']['linux_x86'] = nil
default['nodejs']['install_method'] = 'binary'

# set attributes through test kitchen
default['vsts_build_agent_test']['vsts_url'] = nil
default['vsts_build_agent_test']['vsts_pool'] = nil
default['vsts_build_agent_test']['vsts_user'] = nil
default['vsts_build_agent_test']['vsts_token'] = nil
