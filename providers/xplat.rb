require 'chef/mixin/shell_out'
require 'json'

include ::VSTS::Build::Agent::Helpers

use_inline_resources

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::VstsBuildAgentXplat.new(@new_resource.name)
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
      npm_cmd = get_npm_install_cmd(node)
      execute 'Install vsoagent-installer npm package' do
        command npm_cmd
        not_if { node['vsts_build_agent']['xplat']['skip_vsoagent_installer'] }
      end

      directory new_resource.install_dir do
        user new_resource.user
        group new_resource.group
        mode '0755'
        recursive true
        action [:delete, :create]
      end

      execute "Initializing agent \"#{new_resource.agent_name}\"" do
        cwd new_resource.install_dir
        command 'vsoagent-installer'
        user new_resource.user
        group new_resource.group
      end

      template "#{new_resource.install_dir}/.agent" do
        source 'agent_conf.erb'
        variables(:agent => new_resource)
        owner new_resource.user
        group new_resource.group
        cookbook 'vsts_build_agent'
      end

      cookbook_file "#{new_resource.install_dir}/agent/vsoagent_configurator.js" do
        source 'vsoagent_configurator.js'
        owner new_resource.user
        group new_resource.group
        cookbook 'vsts_build_agent'
      end

      execute "Configuring agent \"#{new_resource.agent_name}\"" do
        cwd new_resource.install_dir
        command "node agent/vsoagent_configurator install -u #{new_resource.vsts_user} -p #{new_resource.vsts_token} -s #{new_resource.vsts_url} -a #{new_resource.agent_name} -l #{new_resource.vsts_pool} -b false"
        user new_resource.user
        group new_resource.group
      end

      if new_resource.user_home && !new_resource.sv_envs.key?('HOME')
        new_resource.sv_envs['HOME'] = new_resource.user_home
      end

      if mac_os_x?
        plist = plist_path new_resource

        directory "#{new_resource.user_home}/Library/LaunchDaemons" do
          user new_resource.user
          group new_resource.group
          mode '0755'
          action :create
          only_if { new_resource.user_home }
        end

        template plist do
          source "#{new_resource.sv_template}.plist.erb"
          cookbook new_resource.sv_cookbook
          user new_resource.user if new_resource.user_home
          group new_resource.group if new_resource.user_home
          variables(
            :agent => new_resource
          )
        end

        cmd = launchctl_load @new_resource
        execute cmd do
          user new_resource.user if new_resource.user_home
          group new_resource.group if new_resource.user_home
          action :run
        end

      else
        runit_service new_resource.sv_name do
          options(
            :agent => new_resource
          )
          owner new_resource.user
          group new_resource.group
          cookbook new_resource.sv_cookbook
          run_template_name new_resource.sv_template
          log_template_name new_resource.sv_template
          sv_timeout new_resource.sv_timeout
          sv_verbose true
          action :enable
        end
        ruby_block 'Wait for service setup' do
          block do
            # TODO: remove when runit cookbook will wait for service setup
            sleep new_resource.sv_wait_timeout
          end
        end
        runit_service new_resource.sv_name do
          action :start
        end

      end

      save_current_state(new_resource, node)
      Chef::Log.info "\"#{new_resource.agent_name}\" agent was installed"
      new_resource.updated_by_last_action(true)
    end
  end
end

action :remove do
  if @current_resource.exists
    converge_by("Removing agent \"#{@current_resource.agent_name}\"") do
      if mac_os_x?
        plist = plist_path @current_resource
        cmd = launchctl_unload @current_resource
        execute "Unload service for #{@current_resource.agent_name}" do
          user current_resource.user if current_resource.user_home
          group current_resource.group if current_resource.user_home
          command cmd
          only_if { ::File.exist?(plist) }
          action :run
        end

        file plist do
          action :delete
        end
      else
        runit_service @current_resource.sv_name do
          action [:stop, :disable]
        end
      end

      execute "Delete agent \"#{@current_resource.agent_name}\" from server" do
        cwd current_resource.install_dir
        command "node agent/vsoagent_configurator remove -u #{current_resource.vsts_user} -p #{current_resource.vsts_token} -s #{current_resource.vsts_url} -a #{current_resource.agent_name} -l #{current_resource.vsts_pool} -b false"
        user current_resource.user
        group current_resource.group
      end
      directory @current_resource.install_dir do
        recursive true
        action :delete
      end
      remove_current_state(@current_resource, node)
      Chef::Log.info "\"#{@current_resource.agent_name}\" agent was removed"
      new_resource.updated_by_last_action(true)
    end
  end
end

action :restart do
  if @current_resource.exists
    converge_by("Restarting agent \"#{@current_resource.agent_name}\"") do
      if mac_os_x?
        cmd = launchctl_unload @current_resource
        execute cmd do
          user current_resource.user if current_resource.user_home
          group current_resource.group if current_resource.user_home
          action :run
        end
        cmd = launchctl_load @current_resource
        execute cmd do
          user current_resource.user if current_resource.user_home
          group current_resource.group if current_resource.user_home
          action :run
        end

      else
        runit_service @current_resource.sv_name do
          action :restart
        end
      end

      Chef::Log.info "\"#{@current_resource.agent_name}\" agent was restarted"
      new_resource.updated_by_last_action(true)
    end
  end
end

private

def mac_os_x?
  platform_family?('mac_os_x') || platform_family?('mac_os_x_server')
end
