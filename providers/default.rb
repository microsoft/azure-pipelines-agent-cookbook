require 'chef/mixin/shell_out'
require 'json'

include ::VSTS::Build::Agent::Helpers
include ::Windows::Helper

use_inline_resources

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::VstsBuildAgent.new(@new_resource.name)
  @current_resource.agent_name(@new_resource.agent_name)
  load_current_state(@current_resource, node)
  @current_resource
end

action :install do
  log "Install: #{@current_resource.exists}"
  log "Install: #{@current_resource.install_dir}"
  if @current_resource.exists
    Chef::Log.info "#{new_resource.agent_name} agent already exists - nothing to do"
  else
    converge_by("Installing agent '#{new_resource.agent_name}'") do
      version = new_resource.version || node['vsts_build_agent']['binary']['version']
      archive_url = download_url(version, node)
      archive_name = archive_name(new_resource)
      unpack_dir = ::File.join(Chef::Config[:file_cache_path], "unpack_agent")
      unpack_dir = win_friendly_path(unpack_dir) if windows?
      
      directory new_resource.install_dir do
        recursive true
        action :delete
      end
      
      directory unpack_dir do
        recursive true
        action :delete
      end
      
      ark archive_name do
        url archive_url
        backup false
        path unpack_dir
        owner new_resource.user
        strip_components 0 if windows?
        action :put
      end
      
      directory new_resource.install_dir do
        recursive true
        rights :full_control, new_resource.user, :applies_to_children => true if windows?
        user new_resource.user
        group new_resource.group
        mode '0755'
        action :create
      end
      
      execute "Move #{new_resource.agent_name} agent from intermidiate folder" do
        command "cp -r #{unpack_dir}/#{archive_name}/* #{new_resource.install_dir}" unless windows?
        command "xcopy #{unpack_dir}\\#{archive_name}\\* #{win_friendly_path(new_resource.install_dir)} /s /e" if windows?
        action :run
      end
      
      args = {
        'configure' => nil,
        'unattended' => nil,
        'replace' => nil,
        'url' => new_resource.vsts_url,
        'pool' => new_resource.vsts_pool,
        'agent' => new_resource.agent_name,
        'work' => new_resource.work_folder
      }
      
      if new_resource.runasservice
        args['runasservice'] = nil
        if windows?
          args['windowslogonaccount'] = new_resource.windowslogonaccount
          args['windowslogonpassword'] = new_resource.windowslogonpassword if new_resource.windowslogonpassword
        end
      else
        args['nostart']  = nil
      end
      
      args['auth'] = new_resource.vsts_auth
      if new_resource.vsts_auth == 'PAT'
        args['token'] = new_resource.vsts_token
      elsif (new_resource.vsts_auth == 'Negotiate') || (new_resource.vsts_auth == 'ALT')
        args['--username'] = new_resource.vsts_username
        args['--password'] = new_resource.vsts_password
      else
        #Integrated Auth: does not take any additional arguments
      end
      
      execute "Configuring agent '#{new_resource.agent_name}'" do
        cwd "#{new_resource.install_dir}/bin"
        sensitive true if respond_to?(:sensitive)
        command vsagentexec(args)
        action :run
      end
      
      execute "Fix permissions for agent '#{new_resource.agent_name}'" do
        command "chown -R #{new_resource.user}:#{new_resource.group} #{new_resource.install_dir}"
        action :run
        not_if { windows? }
      end
      
      execute "Install nix service for '#{new_resource.agent_name}'" do
        cwd new_resource.install_dir
        command "./svc.sh install"
        action :run
        not_if { windows? }
      end
     
      
      ruby_block "save state for agent '#{new_resource.agent_name}'" do
        block do
          save_current_state(new_resource, node)
          Chef::Log.info "'#{new_resource.agent_name}' agent was installed"
        end
        action :run
      end
      new_resource.updated_by_last_action(true)
    end
  end
end

action :remove do
  log "Remove: #{@current_resource.exists}"
  log "Remove: #{@current_resource.install_dir}"
  if @current_resource.exists
    converge_by("Removing agent '#{current_resource.agent_name}'") do
      
      sn = service_name(@current_resource)
      service sn do
        action [:stop, :disable]
        ignore_failure true
      end
      
      execute "Uninstall nix service for '#{new_resource.agent_name}'" do
        cwd current_resource.install_dir
        command "./svc.sh uninstall"
        action :run
        not_if { windows? }
      end
      
      args = {
        'remove' => nil,
        'unattended' => nil
      }
      
      args['auth'] = new_resource.vsts_auth
      if new_resource.vsts_auth == 'PAT'
        args['token'] = new_resource.vsts_token
      elsif (new_resource.vsts_auth == 'Negotiate') || (new_resource.vsts_auth == 'ALT')
        args['--username'] = new_resource.vsts_username
        args['--password'] = new_resource.vsts_password
      else
        #Integrated Auth: does not take any additional arguments
      end
      
      execute "Unconfiguring agent '#{current_resource.agent_name}'" do
        cwd "#{current_resource.install_dir}/bin"
        command vsagentexec(args)
        action :run
      end
      
      ruby_block "remove state for agent '#{current_resource.agent_name}'" do
        block do
          remove_current_state(current_resource, node)
          Chef::Log.info "'#{current_resource.agent_name}' agent was removed"
        end
        action :run
      end
      new_resource.updated_by_last_action(true)
      
    end
  end
end

action :restart do
  log "Restart: #{@current_resource.exists}"
  log "Restart: #{@current_resource.install_dir}"
  if @current_resource.exists
    converge_by("Restarting agent '#{current_resource.agent_name}'") do
      sn = service_name(@current_resource)
      
      service sn do
        action :restart
      end
      
      log "'#{current_resource.agent_name}' agent was restarted"
     
      new_resource.updated_by_last_action(true)
    end
  end
end
