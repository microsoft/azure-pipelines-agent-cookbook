
include_recipe 'apt::default' if platform_family?('debian')

include_recipe 'vsts_build_agent::default'

include_recipe 'build-essential::default'
include_recipe 'vsts_build_agent::default'

agent1_name = "#{node['hostname']}_01"
agent2_name = "#{node['hostname']}_02"

if platform_family?('mac_os_x')
  home_dir = '/Users/vagrant'

  bash 'Prepare dirs for the homebrew' do
    code <<-EOH
      mkdir -p /usr/local
      chown -R vagrant:staff /usr/local
      EOH
  end

  node.set['homebrew']['owner'] = 'vagrant'
  include_recipe 'homebrew'

  execute 'Install nodejs from brew' do
    command 'brew install node'
    user 'vagrant'
    group 'staff'
    action :run
  end

else
  home_dir = '/home/vagrant'
  include_recipe 'nodejs::default'
  include_recipe 'nodejs::npm'
  execute 'Set npm global prefix' do
    command 'npm config set prefix /usr/local'
  end
end

# # cleanup
vsts_build_agent_xplat agent1_name do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

vsts_build_agent_xplat agent2_name do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

vsts_build_agent_xplat agent1_name do
  install_dir "#{home_dir}/agents/agent_01"
  user 'vagrant'
  group 'vagrant'
  sv_envs(
    'PATH' => '/usr/local/bin/:/opt/local/bin:/sbin:/usr/sbin:/bin:/usr/bin',
    'TEST' => 'agent1'
  )
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_user node['vsts_build_agent_test']['vsts_user']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :install
end

vsts_build_agent_xplat agent2_name do
  install_dir "#{home_dir}/agents/agent_02"
  user 'vagrant'
  group 'vagrant'
  user_home home_dir
  sv_name 'agent2'
  sv_envs(
    'PATH' => '/usr/local/bin/:/opt/local/bin:/sbin:/usr/sbin:/bin:/usr/bin',
    'TEST' => 'agent2'
  )
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_user node['vsts_build_agent_test']['vsts_user']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :install
  notifies :restart, "vsts_build_agent_xplat[#{agent2_name}]", :delayed
end

vsts_build_agent_xplat "Restart '#{agent1_name}'" do
  agent_name agent1_name
  action :restart
end

vsts_build_agent_xplat "Remove '#{agent1_name}'" do
  agent_name agent1_name
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end
