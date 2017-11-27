resource_name :vsts_agent

default_action :install

property :agent_name, String, name_property: true
property :install_dir, String

property :user, String, desired_state: false
property :group, String, desired_state: false

property :work_folder, String, default: '_work'

property :runasservice, [TrueClass, FalseClass], default: true
property :windowslogonaccount, String, desired_state: false
property :windowslogonpassword, String, desired_state: false

# environment
property :version, String, desired_state: false
property :path, String, desired_state: false
property :env, Hash, default: {}, desired_state: false

# VSTS Access
property :vsts_url, String, regex: %r{^https?://.*$}
property :vsts_pool, String
property :vsts_auth, String, default: 'PAT', desired_state: false
property :vsts_username, String, desired_state: false
property :vsts_password, String, sensitive: true, desired_state: false
property :vsts_token, String, sensitive: true, desired_state: false

include ::VSTS::Agent::Helpers

load_current_value do
  state = load_state(agent_name)
  current_value_does_not_exist! unless state
  install_dir state['install_dir']
  current_value_does_not_exist! unless install_dir
  current_value_does_not_exist! unless agent_exists?(install_dir)
  user state['user']
  group state['group']
  vsts_url state['vsts_url']
  vsts_pool state['vsts_pool']
  work_folder state['work_folder']

  runasservice service_exist?(install_dir)
end

action :install do
  version = new_resource.version || node['vsts_agent']['binary']['version']

  ruby_block "Restart vsts_agent #{new_resource.agent_name} service" do
    block do
      service = ::VSTS::Agent::Service.new(new_resource.agent_name, new_resource.install_dir, new_resource.user, new_resource.group)
      service.restart
    end
    action :nothing
  end

  converge_if_changed do
    archive_url = download_url(version)
    archive_name = archive_name(version)
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
      rights :full_control, new_resource.user, applies_to_children: true if windows?
      user new_resource.user
      group new_resource.group
      mode '0755' unless windows?
      action :create
    end

    execute "Move #{new_resource.agent_name} agent from intermidiate folder" do
      command "cp -r #{unpack_dir}/#{archive_name}/* #{new_resource.install_dir}" unless windows?
      command "xcopy #{unpack_dir}\\#{archive_name}\\* #{win_friendly_path(new_resource.install_dir)} /s /e /q" if windows?
      action :run
    end

    args = {
      configure: nil,
      unattended: nil,
      replace: nil,
      url: new_resource.vsts_url,
      pool: new_resource.vsts_pool,
      agent: new_resource.agent_name,
      work: new_resource.work_folder,
    }

    if new_resource.runasservice
      args[:runasservice] = nil
      args[:windowslogonaccount] = new_resource.windowslogonaccount if windows?
      if windows? && new_resource.windowslogonpassword
        args[:windowslogonpassword] = new_resource.windowslogonpassword
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

    ruby_block "Install service for agent '#{new_resource.agent_name}'" do
      block do
        service = ::VSTS::Agent::Service.new(new_resource.agent_name, new_resource.install_dir, new_resource.user, new_resource.group)
        service.enable
        service.start
      end
      only_if { new_resource.runasservice }
    end

    ruby_block "Save '#{new_resource.agent_name}' agent state" do
      block do
        save_state(new_resource.agent_name, install_dir: new_resource.install_dir,
                                            user: new_resource.user,
                                            group: new_resource.group,
                                            vsts_url: new_resource.vsts_url,
                                            vsts_pool: new_resource.vsts_pool,
                                            work_folder: new_resource.work_folder)
        Chef::Log.info "'#{new_resource.agent_name}' agent was installed"
      end
      action :run
    end
  end

  template "#{new_resource.install_dir}/.path" do
    source 'path.erb'
    variables(path: new_resource.path)
    user new_resource.user
    group new_resource.group
    mode '0755' unless windows?
    action :create
    cookbook 'vsts_agent'
    notifies :run, "ruby_block[Restart vsts_agent #{new_resource.agent_name} service]", :delayed if new_resource.runasservice
    not_if { new_resource.path.nil? }
  end

  template "#{new_resource.install_dir}/.env" do
    source 'env.erb'
    variables(env: new_resource.env)
    user new_resource.user
    group new_resource.group
    mode '0755' unless windows?
    cookbook 'vsts_agent'
    notifies :run, "ruby_block[Restart vsts_agent #{new_resource.agent_name} service]", :delayed if new_resource.runasservice
    action :create
    not_if { new_resource.env.nil? || new_resource.env.empty? }
  end
end

action :remove do
  if current_resource && current_resource.install_dir # ~FC023
    converge_by("Removing agent '#{current_resource.agent_name}'") do
      remove_agent(current_resource)
      ruby_block "remove state for agent '#{current_resource.agent_name}'" do
        block do
          remove_current_state(current_resource)
          Chef::Log.info "'#{current_resource.agent_name}' agent was removed"
        end
        action :run
      end
    end
  end
end

action :restart do
  if current_resource && current_resource.install_dir && current_resource.runasservice # ~FC023
    converge_by("Restarting agent '#{current_resource.agent_name}'") do
      ruby_block "Restart vsts_agent #{current_resource.agent_name} service" do
        block do
          service = ::VSTS::Agent::Service.new(current_resource.agent_name, current_resource.install_dir, current_resource.user, current_resource.group)
          service.restart
          Chef::Log.info "'#{current_resource.agent_name}' agent was restarted"
        end
        action :run
      end
    end
  end
end

action_class do
  require 'json'

  # rubocop:disable all
  def remove_agent(resource)

      ruby_block "Disable vsts_agent['#{resource.agent_name}'] service" do
          block do
              service = ::VSTS::Agent::Service.new(resource.agent_name, resource.install_dir, resource.user, resource.group)
              service.stop
              service.disable
          end
          action :run
      end
  
      args = {
          remove: nil,
          unattended: nil
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
end
