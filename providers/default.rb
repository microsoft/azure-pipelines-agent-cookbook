require 'chef/mixin/shell_out'
require 'json'

include ::VSTS::Agent::Helpers
include ::Windows::Helper

use_inline_resources

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::ResourceResolver.resolve(:vsts_agent).new(@new_resource.name)
  @current_resource.agent_name(@new_resource.agent_name)
  @current_resource.vsts_token(@new_resource.vsts_token)
  load_current_state(@current_resource, node)
  @current_resource
end

action :install do
  version = new_resource.version || node['vsts_agent']['binary']['version']

  vsts_agent_service new_resource.agent_name do
    install_dir new_resource.install_dir
    user new_resource.user
    group new_resource.group
    action :nothing
    only_if { new_resource.runasservice }
  end

  service_id = "vsts_agent_service[#{new_resource.agent_name}]"

  if @current_resource.exists
    Chef::Log.info "'#{new_resource.agent_name}' agent '#{current_resource.version}' already exists - nothing to do"
  else
    converge_by("Installing agent '#{new_resource.agent_name}' version '#{version}'") do
      archive_url = download_url(version, node)
      archive_name = archive_name(new_resource)
      unpack_dir = ::File.join(Chef::Config[:file_cache_path], 'unpack_agent')
      unpack_dir = win_friendly_path(unpack_dir) if windows?

      remove_agent(new_resource)

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
        only_if { osx? && new_resource.runasservice }
      end

      log "Trigger service installation for agent #{new_resource.agent_name}" do
        notifies :enable, service_id, :immediately if new_resource.runasservice
      end


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

  template "#{new_resource.install_dir}/.path" do
    source 'path.erb'
    variables(:path => new_resource.path)
    user new_resource.user
    group new_resource.group
    mode '0755'
    action :create
    cookbook 'vsts_agent'
    notifies :restart, service_id, :immediately if new_resource.runasservice
    only_if { new_resource.path }
  end

  template "#{new_resource.install_dir}/.env" do
    source 'env.erb'
    variables(:env => new_resource.env)
    user new_resource.user
    group new_resource.group
    mode '0755'
    cookbook 'vsts_agent'
    notifies :restart, service_id, :immediately if new_resource.runasservice
    action :create
  end
end

action :remove do
  if @current_resource.exists # ~FC023
    converge_by("Removing agent '#{current_resource.agent_name}'") do
      remove_agent(current_resource)
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
  if @current_resource.exists # ~FC023
    converge_by("Restarting agent '#{current_resource.agent_name}'") do
      vsts_agent_service current_resource.agent_name do
        install_dir current_resource.install_dir
        user current_resource.user
        group current_resource.group
        action :restart
        only_if { current_resource.runasservice }
      end

      log "'#{current_resource.agent_name}' agent was restarted"
      new_resource.updated_by_last_action(true)
    end
  end
end

# rubocop:disable all
def remove_agent(resource)
  vsts_agent_service "Restart service #{resource.agent_name}" do
    name resource.agent_name
    install_dir resource.install_dir
    user resource.user
    group resource.group
    action [:stop, :disable]
    only_if { service_exist?(resource.install_dir) }
  end

  args = {
    'remove' => nil,
    'unattended' => nil
  }

  set_auth(args, resource)

  execute "Unconfiguring agent '#{resource.agent_name}'" do
    cwd "#{resource.install_dir}/bin"
    command vsagentexec(args)
    sensitive true if respond_to?(:sensitive)
    action :run
    only_if { agent_exists?(resource.install_dir) }
  end

  directory resource.install_dir do
    recursive true
    action :delete
  end
end
# rubocop:enable all