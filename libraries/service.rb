require 'chef/resource/lwrp_base'
require 'chef/provider/lwrp_base'
require 'chef/mixin/shell_out'
require 'chef/mixin/language'

class Chef
  class Resource
    # Internal Resource/Provider to manage agent service
    class VstsAgentService < Chef::Resource::LWRPBase
      provides :vsts_agent_service
      resource_name :vsts_agent_service

      actions :enable, :start, :stop, :restart, :disable

      default_action :enable

      attribute :name, :kind_of => String, :name_attribute => true
      attribute :install_dir, :kind_of => String
      attribute :user, :kind_of => String
      attribute :group, :kind_of => String
    end
  end
end

class Chef
  class Provider
    # Internal Resource/Provider to manage agent service
    class VstsAgentService < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut
      include Windows::Helper
      include VSTS::Agent::Helpers

      use_inline_resources

      action :enable do
        unless service_exist?(new_resource.install_dir) && windows?
          vsts_service 'install'
          new_resource.updated_by_last_action(true)
        end
      end

      action :start do
        if service_exist?(new_resource.install_dir)
          vsts_service 'start'
          new_resource.updated_by_last_action(true)
        end
      end

      action :stop do
        if service_exist?(new_resource.install_dir)
          vsts_service 'stop'
          new_resource.updated_by_last_action(true)
        end
      end

      action :restart do
        if service_exist?(new_resource.install_dir)
          vsts_service 'stop'
          vsts_service 'start'
          new_resource.updated_by_last_action(true)
        end
      end

      action :disable do
        if service_exist?(new_resource.install_dir)
          vsts_service 'disable'
          new_resource.updated_by_last_action(true)
        end
      end

      def service_name
        @service_name ||= ::File.read("#{new_resource.install_dir}/.service").strip
      end

      def vsts_service(operation)
        if windows?
          vsts_windows_service(operation)
        else
          vsts_unix_service(operation)
        end
      end

      def vsts_windows_service(operation)
        return if action == 'install'
        service service_name do
          action operation
          retries 3
        end
      end

      def vsts_unix_service(operation)
        if operation == 'install'
          operation = "#{operation} #{new_resource.user}"
        elsif operation == 'disable'
          operation = 'uninstall'
        end
        envvars = { 'HOME' => "/Users/#{new_resource.user}" }
        execute "Run action '#{operation}' on service '#{new_resource.name}'" do
          cwd new_resource.install_dir
          command "./svc.sh #{operation}"
          user new_resource.user if osx?
          group new_resource.group if osx?
          environment envvars if osx?
          action :run
          retries 3
        end
      end
    end
  end
end
