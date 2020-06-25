apt_update if platform_family?('debian')
build_essential 'install compilation tools'

user node['vsts_agent_test']['username'].to_s do
  manage_home true
  comment 'Vagrant user'
  home "/home/#{node['vsts_agent_test']['username']}"
  shell '/bin/bash'
  not_if "id -u #{node['vsts_agent_test']['username']}"
end

user 'builder' do
  manage_home true
  comment 'Builder user'
  home '/home/builder'
  shell '/bin/bash'
end

include_recipe 'vsts_agent::default'

agent1_name = "#{node['hostname']}_01"
agent2_name = "#{node['hostname']}_02"
agent3_name = "#{node['hostname']}_deployment_03"

agents_dir = '/opt/agents'

# cleanup
vsts_agent agent1_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :remove
end

vsts_agent agent2_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :remove
end

vsts_agent agent3_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :remove
end

log 'Test notification' do
  action :nothing
end

# # Agent1
vsts_agent agent1_name do
  install_dir "#{agents_dir}/#{agent1_name}"
  user node['vsts_agent_test']['username']
  group node['vsts_agent_test']['username']
  vsts_url node['vsts_agent_test']['vsts_url']
  vsts_pool node['vsts_agent_test']['vsts_pool']
  vsts_token node['vsts_agent_test']['vsts_token']
  action :install
  notifies :write, 'log[Test notification]', :immediately
end

vsts_agent agent1_name do
  action :restart
end

vsts_agent agent1_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :remove
end

# Agent2
vsts_agent agent2_name do
  install_dir "#{agents_dir}/#{agent2_name}"
  user 'builder'
  group 'builder'
  path '/usr/local/bin/:/usr/bin:/opt/bin/:/tmp/'
  env('M2_HOME' => '/opt/maven', 'JAVA_HOME' => '/opt/java')
  vsts_url node['vsts_agent_test']['vsts_url']
  vsts_pool node['vsts_agent_test']['vsts_pool']
  vsts_token node['vsts_agent_test']['vsts_token']
  work_folder '/tmp/work'
  action :install
end

vsts_agent agent2_name do
  action :restart
end

# Agent 3 deployment group
vsts_agent agent3_name do
  deploymentGroup true
  deploymentGroupName node['vsts_agent_test']['deployment_group_name']
  projectName node['vsts_agent_test']['deployment_group_project']
  deploymentGroupTags 'web, db'
  install_dir "#{agents_dir}/#{agent3_name}"
  user 'builder'
  group 'builder'
  path '/usr/local/bin/:/usr/bin:/opt/bin/:/tmp/'
  env('M2_HOME' => '/opt/maven', 'JAVA_HOME' => '/opt/java')
  vsts_url node['vsts_agent_test']['vsts_url']
  vsts_token node['vsts_agent_test']['vsts_token']
  work_folder '/tmp/work'
  action :install
end

vsts_agent agent3_name do
  action :restart
end
