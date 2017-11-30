require 'chef/resource/lwrp_base'
require 'chef/provider/lwrp_base'
require 'chef/mixin/shell_out'
require 'chef/mixin/language'

module VSTS
  module Agent
    # The service operations for vsts_agent
    class Service
      include Windows::Helper
      include VSTS::Agent::Helpers
      include Chef::DSL::PlatformIntrospection

      def initialize(agent_name, install_dir, user, group)
        @agent_name = agent_name
        @install_dir = install_dir
        @user = user
        @group = group
      end

      def enable
        vsts_service 'enable' unless service_exist?(@install_dir)
      end

      def start
        vsts_service 'start' if service_exist?(@install_dir)
      end

      def stop
        vsts_service 'stop' if service_exist?(@install_dir)
      end

      def restart
        return unless service_exist?(@install_dir)
        vsts_service 'stop'
        vsts_service 'start'
      end

      def disable
        vsts_service 'disable' if service_exist?(@install_dir)
      end

      # used by platforms introspection
      def node
        Chef.run_context.node
      end

      def service_name
        return unless service_exist?(@install_dir)
        @service_name ||= ::File.read("#{@install_dir}/.service").strip
      end

      def vsts_service(action)
        if windows?
          vsts_windows_service(action)
        else
          vsts_unix_service(action)
        end
      end

      def vsts_windows_service(action)
        return if action == 'enable' # service is installed by agent
        win_service = Chef::Resource::WindowsService.new(service_name, Chef.run_context)
        win_service.retries(3)
        win_service.run_action(action.to_sym)
      end

      def vsts_unix_service(action)
        if action == 'enable'
          action = "install #{@user}"
        elsif action == 'disable'
          action = 'uninstall'
        end
        envvars = { HOME: "/Users/#{@user}" }
        execute = Chef::Resource::Execute.new("Run action '#{action}' on service for agent '#{@agent_name}'", Chef.run_context)
        execute.cwd(@install_dir)
        execute.command("./svc.sh #{action}")
        if osx?
          execute.user(@user)
          execute.group(@group)
          execute.environment(envvars)
        end
        execute.run_action(:run)
      end
    end
  end
end
