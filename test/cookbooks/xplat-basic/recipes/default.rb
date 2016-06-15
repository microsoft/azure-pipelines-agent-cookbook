#### Begin prepare system ####
include_recipe 'apt::default' if platform_family?('debian')

if platform_family?('windows')
   
  cookbook_file "#{Chef::Config[:file_cache_path]}/Grant-LogOnAsService.ps1" do
      source 'Grant-LogOnAsService.ps1'
      action :create_if_missing
  end

  # grant ServiceLogon rights
  batch "grant servicelogon rights to vagrant" do
      cwd Chef::Config[:file_cache_path]
      code <<-EOH
          powershell -ExecutionPolicy Bypass ./Grant-LogOnAsService.ps1 -userAlias vagrant 
          if %ERRORLEVEL% == 0 echo "Service logon access to vagrant granted" > "#{Chef::Config[:file_cache_path]}\\logon.guard"
      EOH
      not_if {::File.exists?("#{Chef::Config[:file_cache_path]}\\logon.guard")}
  end
  
end
include_recipe 'build-essential::default' unless platform_family?('windows')

#### End prepare system ####

include_recipe 'vsts_build_agent::default'

agent1_name = "#{node['hostname']}_01"
agent2_name = "#{node['hostname']}_02"

agents_dir = '/home/vagrant/agents'
agents_dir = '/Users/vagrant/agents' if platform_family?('mac_os_x')
agents_dir = 'C:\\Users\\vagrant\\agents' if platform_family?('windows')


# cleanup
vsts_build_agent agent1_name do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

vsts_build_agent agent2_name do
  vsts_token node['vsts_build_agent_test']['vsts_token']
  action :remove
end

# Agent1
vsts_build_agent agent1_name do
  version '2.102.0'
  install_dir "#{agents_dir}/#{agent1_name}"
  user 'vagrant'
  group 'vagrant'
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  windowslogonaccount 'vagrant'
  windowslogonpassword 'vagrant'
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
  version '2.102.0'
  install_dir "#{agents_dir}/#{agent2_name}"
  user 'vagrant'
  group 'vagrant'
  vsts_url node['vsts_build_agent_test']['vsts_url']
  vsts_pool node['vsts_build_agent_test']['vsts_pool']
  vsts_token node['vsts_build_agent_test']['vsts_token']
  windowslogonaccount 'NT AUTHORITY\\NetworkService'
  action :install
end

vsts_build_agent agent2_name do
  action :restart
end
