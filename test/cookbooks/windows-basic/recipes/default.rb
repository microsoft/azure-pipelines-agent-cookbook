#### Begin prepare system ####
user 'builder' do
  comment 'Builder user'
  home '/home/builder'
  shell '/bin/bash'
  password 'Pas$w0r_d'
end

grant_logon_as_service node['vsts_agent_test']['username']
grant_logon_as_service 'builder'

#### End prepare system ####

include_recipe 'vsts_agent::default'

agent1_name = "win_#{node['hostname']}_01"
agent2_name = "win_#{node['hostname']}_02"

agents_dir = 'C:\\agents'

log 'Test notification' do
  action :nothing
end

# cleanup
vsts_agent agent1_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :remove
end

vsts_agent agent2_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :remove
end

# Agent1
vsts_agent agent1_name do
  install_dir "#{agents_dir}\\#{agent1_name}"
  user node['vsts_agent_test']['username']
  vsts_url node['vsts_agent_test']['vsts_url']
  vsts_pool node['vsts_agent_test']['vsts_pool']
  vsts_token node['vsts_agent_test']['vsts_token']
  windowslogonaccount node['vsts_agent_test']['username']
  windowslogonpassword node['vsts_agent_test']['username']
  notifies :write, 'log[Test notification]', :immediately
  action :install
end

vsts_agent agent1_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :restart
end

vsts_agent agent1_name do
  vsts_token node['vsts_agent_test']['vsts_token']
  action :remove
end

# Agent2
vsts_agent agent2_name do
  install_dir "#{agents_dir}\\#{agent2_name}"
  user 'builder'
  vsts_url node['vsts_agent_test']['vsts_url']
  vsts_pool node['vsts_agent_test']['vsts_pool']
  vsts_token node['vsts_agent_test']['vsts_token']
  windowslogonaccount 'NT AUTHORITY\\NetworkService'
  action :install
end

vsts_agent agent2_name do
  action :restart
end
