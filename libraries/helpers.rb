module VSTS
  module Agent
    # Helper methods for VSTS Build Agent installation
    module Helpers
      include Chef::DSL::PlatformIntrospection

      require 'json'
      require 'fileutils'

      def archive_name(version)
        name = 'vsts_agent'
        name += '_' + version if version
        name
      end

      def download_url(version)
        url = Chef.run_context.node['vsts_agent']['binary']['url']
        url.gsub '%s', version
      end

      def windows?
        platform_family?('windows')
      end

      def debian?
        platform_family?('debian')
      end

      def rhel?
        platform_family?('rhel')
      end

      def osx?
        platform_family?('mac_os_x') || platform_family?('mac_os_x_server')
      end

      def service_exist?(install_dir)
        ::File.exist?("#{install_dir}/.service")
      end

      def agent_exists?(install_dir)
        ::File.exist?("#{install_dir}/.agent")
      end

      def save_state(agent_name, hash = {})
        ::File.write(state_file(agent_name), hash.to_json)
      end

      def load_state(agent_name)
        state_file = state_file(agent_name)
        return unless ::File.exist?(state_file)
        state = ::File.read(state_file(agent_name))
        JSON.parse(state)
      end

      def state_file(agent_name)
        save_dir = "#{Chef::Config[:file_cache_path]}/vsts_agent"
        ::FileUtils.mkdir_p save_dir unless ::File.directory?(save_dir)
        "#{save_dir}/#{agent_name}-state.json"
      end

      def remove_current_state(agent_name)
        state_file = state_file(agent_name)
        ::File.delete(state_file) if ::File.exist?(state_file)
      end

      def set_auth(args, resource)
        args['auth'] = resource.vsts_auth.downcase
        if args['auth'] == 'pat'
          args['token'] = resource.vsts_token
        elsif (args['auth'] == 'negotiate') || (args['auth'] == 'alt')
          args['username'] = resource.vsts_username
          args['password'] = resource.vsts_password
        end
      end

      def vsagentexec(args = {})
        command = 'Agent.Listener '
        command = './' + command unless windows?
        args.each { |key, value| command += append_arguments(key.to_s, value) + ' ' }
        command
      end

      def append_arguments(key, value)
        result = ''
        if key.include?('configure') || key.include?('remove')
          result += key
        else
          result += "--#{key}"
          result += " \"#{value}\"" unless value.nil?
        end
        result
      end
    end
  end
end
