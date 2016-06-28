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
  condidate_version = new_resource.version || node['vsts_build_agent']['binary']['version']
  need_upgrade = current_resource.version != condidate_version
  if @current_resource.exists && !need_upgrade
    Chef::Log.info "'#{new_resource.agent_name}' agent '#{current_resource.version}' already exists - nothing to do"
  else
    converge_by("Installing agent '#{new_resource.agent_name}' version '#{condidate_version}'") do
      version = condidate_version
      archive_url = download_url(version, node)
      archive_name = archive_name(new_resource)
      unpack_dir = ::File.join(Chef::Config[:file_cache_path], 'unpack_agent')
      unpack_dir = win_friendly_path(unpack_dir) if windows?

      if current_resource.exists && need_upgrade
        Chef::Log.info "'#{new_resource.agent_name}' agent will be upgradet to version '#{current_resource.version}'"
        remove_agent(current_resource, new_resource)
      end

      config = service_config(new_resource)
      execute "Remove service config file #{config}" do
        command "rm -rf #{config}"
        action :run
        not_if { windows? }
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
        end
        if windows? && new_resource.windowslogonpassword
          args['windowslogonpassword'] = new_resource.windowslogonpassword
        end
      else
        args['nostart'] = nil
      end

      set_auth(args, new_resource)

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

      directory "/Users/#{new_resource.user}/Library/LaunchAgents" do
        owner new_resource.user
        group new_resource.group
        mode '0755'
        action :create
        only_if { osx? }
      end

      manage_service("install #{new_resource.user}", new_resource) if new_resource.runasservice
      manage_service('restart', new_resource) if new_resource.runasservice

      ruby_block "save state for agent '#{new_resource.agent_name}'" do
        block do
          save_vars(new_resource, node)
          Chef::Log.info "'#{new_resource.agent_name}' agent was installed"
        end
        action :run
      end
      new_resource.updated_by_last_action(true)
    end
  end
end

action :remove do
  if @current_resource.exists
    converge_by("Removing agent '#{current_resource.agent_name}'") do
      remove_agent(current_resource, new_resource)
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
  if @current_resource.exists
    converge_by("Restarting agent '#{current_resource.agent_name}'") do
      manage_service('restart', current_resource) if current_resource.runasservice
      log "'#{current_resource.agent_name}' agent was restarted"
      new_resource.updated_by_last_action(true)
    end
  end
end

def remove_agent(current_resource, new_resource)
  manage_service('uninstall', current_resource) if current_resource.runasservice

  args = {
    'remove' => nil,
    'unattended' => nil
  }

  set_auth(args, new_resource)

  execute "Unconfiguring agent '#{current_resource.agent_name}'" do
    cwd "#{current_resource.install_dir}/bin"
    command vsagentexec(args)
    sensitive true if respond_to?(:sensitive)
    action :run
  end

  directory current_resource.install_dir do
    recursive true
    action :delete
  end
end

def manage_service(operation, resource)
  if windows?
    manage_windows_service(operation, resource)
  else
    manage_unix_service(operation, resource)
  end
end

def manage_windows_service(operation, resource)
  if operation == 'restart' || operation == 'stop'
    a = [operation.to_sym]
  elsif operation == 'uninstall'
    a = [:stop, :disable]
  else
    return # unsupported operations
  end
  sn = service_name(resource)
  service sn do
    action a
    ignore_failure true
  end
end

def manage_unix_service(operation, resource)
  cmd = if operation == 'restart'
          './svc.sh stop && ./svc.sh start'
        elsif operation == 'uninstall'
          './svc.sh stop && ./svc.sh uninstall'
        else
          "./svc.sh #{operation}"
        end
  envvars = { 'HOME' => "/Users/#{resource.user}" }
  execute "Run action '#{operation}' on service for '#{resource.agent_name}'" do
    cwd resource.install_dir
    command cmd
    user resource.user if osx?
    group resource.group if osx?
    environment envvars if osx?
    action :run
    ignore_failure true
  end
end
