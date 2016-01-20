include_recipe 'vsts_build_agent::default'

agent_prefix = node['hostname']
sys_user = 'vagrant'
sys_passwd = 'vagrant'

# clean previous run
vsts_build_agent_windows "#{agent_prefix}_01" do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

vsts_build_agent_windows "#{agent_prefix}_02" do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

vsts_build_agent_windows "#{agent_prefix}_03" do
  install_dir "c:\\agents\\#{agent_prefix}_03"
  vsts_user node['vsts_build_agent_test']['vsts_user']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

# install agents
# agent with default service name
vsts_build_agent_windows "#{agent_prefix}_01" do
  install_dir 'c:\\agents\\agent_01'
  sv_user sys_user
  sv_password sys_passwd
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_user node['vsts_build_agent_test']['vsts_user']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :install
end

vsts_build_agent_windows "#{agent_prefix}_01" do
  action :restart
end

# agent with overriden service name
# run as Local Service user
vsts_build_agent_windows "#{agent_prefix}_02" do
  install_dir 'c:\\agents\\agent_02'
  sv_user 'NT AUTHORITY\\LocalService'
  sv_name 'agent_02.service'
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_user node['vsts_build_agent_test']['vsts_user']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :install
end

vsts_build_agent_windows "#{agent_prefix}_02" do
  action :restart
end

# agent to remove
vsts_build_agent_windows "#{agent_prefix}_03" do
  install_dir 'c:\\agents\\agent_03'
  sv_user 'NT AUTHORITY\\NetworkService'
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_user node['vsts_build_agent_test']['vsts_user']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :install
end

vsts_build_agent_windows "#{agent_prefix}_03" do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end
