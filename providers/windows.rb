require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut
include ::VSTS::Build::Agent::Helpers

use_inline_resources

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::VstsBuildAgentWindows.new(@new_resource.name)
  @current_resource.agent_name(@new_resource.agent_name)
  @current_resource.exists = false

  load_current_state(@current_resource, node)
  @new_resource.sv_name(service_name(@new_resource))

  if agent_installed?(@current_resource, node)
    @current_resource.vsts_token(@new_resource.vsts_token)
    @current_resource.exists = true
  end
  @current_resource
end

action :install do
  if @current_resource.exists
    Chef::Log.info "#{new_resource.agent_name} agent already exists - nothing to do"
  else
    converge_by("Installing agent \"#{new_resource.agent_name}\"") do
      powershell_script 'Downloading vsoagent' do
        code <<-EOH

  $username = "#{new_resource.vsts_user}"
  $patToken = "#{new_resource.vsts_token}"
  $OutFile = "#{Chef::Config[:file_cache_path]}/vso_agent.zip"

  $auth = ('{0}:{1}' -f $username,$patToken)
  $auth = [System.Text.Encoding]::UTF8.GetBytes($auth)
  $auth = [System.Convert]::ToBase64String($auth)

  $h = @{Authorization=('Basic {0}' -f $auth)}

  $wc = New-Object Net.WebClient
  $wc.Headers.add('Authorization', 'Basic {0}' -f $auth)
  $wc.DownloadFile( "#{new_resource.vsts_url}/_apis/distributedtask/packages/agent", $OutFile )
        EOH
        not_if { ::File.exist?("#{Chef::Config[:file_cache_path]}/vso_agent.zip") }
      end

      directory new_resource.install_dir do
        rights :full_control, new_resource.sv_user, :applies_to_children => true
        recursive true
        action :create
      end

      windows_zipfile new_resource.install_dir do
        source "#{Chef::Config[:file_cache_path]}/vso_agent.zip"
        action :unzip
      end

      powershell_script 'Removing the ZoneIdentifier from files downloaded from the internet' do
        cwd new_resource.install_dir
        code <<-EOH
        Get-ChildItem -Path #{new_resource.install_dir} | Unblock-File | out-null
        Get-ChildItem -Recurse -Path #{new_resource.install_dir}\\Agent | Unblock-File | out-null
        EOH
      end

      args = {
        'configure' => nil,
        'RunningAsService' => nil,
        'serverUrl' => new_resource.vsts_url,
        'WindowsServiceName' => new_resource.sv_name,
        'WindowsServiceLogonAccount' => new_resource.sv_user,
        'WindowsServiceLogonPassword' => new_resource.sv_password,
        'name' => new_resource.agent_name,
        'PoolName' => new_resource.vsts_pool,
        'WorkFolder' => new_resource.work_folder,
        'Login' => "#{new_resource.vsts_user},#{new_resource.vsts_token}",
        'force' => nil,
        'NoPrompt' => nil
      }

      execute "Configuring agent \"#{new_resource.agent_name}\"" do
        cwd new_resource.install_dir
        command vsagentexec(args)
        action :run
      end
    end

    save_current_state(new_resource, node)
    new_resource.updated_by_last_action(true)
    Chef::Log.info "\"#{new_resource.agent_name}\" agent was installed"

  end
end

action :remove do
  if @current_resource.exists
    converge_by("Removing agent \"#{@current_resource.agent_name}\"") do
      args = {
        'unconfigure' => nil,
        'Login' => "#{@current_resource.vsts_user},#{@current_resource.vsts_token}",
        'force' => nil,
        'NoPrompt' => nil
      }

      execute "Unconfiguring agent \"#{@current_resource.agent_name}\"" do
        cwd current_resource.install_dir
        command vsagentexec(args)
        action :run
        retries 3
        retry_delay 15
      end

      directory current_resource.install_dir do
        recursive true
        action :delete
      end
    end
    remove_current_state(@current_resource, node)
    new_resource.updated_by_last_action(true)
    Chef::Log.info "\"#{new_resource.agent_name}\" agent was removed"
  end
end

action :restart do
  if @current_resource.exists
    converge_by("Restarting agent \"#{@current_resource.agent_name}\"") do
      service @current_resource.sv_name do
        action :restart
      end
    end
    new_resource.updated_by_last_action(true)
    Chef::Log.info "\"#{@current_resource.agent_name}\" agent was restarted"
  end
end
