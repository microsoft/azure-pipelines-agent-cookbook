#### Begin prepare system ####
include_recipe 'build-essential::default'
#### End prepare system ####

include_recipe 'vsts_build_agent::default'

agent1_name = "osx_#{node['hostname']}_01"
agent2_name = "osx_#{node['hostname']}_02"

agents_dir = '/Users/vagrant/agents'

# cleanup
vsts_build_agent agent1_name do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

# Agent1
vsts_build_agent agent1_name do
  version '2.102.0'
  install_dir "#{agents_dir}/#{agent1_name}"
  user 'vagrant'
  group 'staff'
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :install
end

vsts_build_agent agent1_name do
  action :restart
end

vsts_build_agent agent1_name do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

# Agent2
vsts_build_agent agent2_name do
  version '2.102.1'
  install_dir "#{agents_dir}/#{agent2_name}"
  user 'vagrant'
  group 'staff'
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :install
end

vsts_build_agent agent2_name do
  action :restart
end
