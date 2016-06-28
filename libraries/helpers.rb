module VSTS
  module Build
    module Agent
      # Helper methods for VSTS Build Agent installation
      module Helpers
        include Chef::DSL::PlatformIntrospection

        require 'json'

        VARS_TO_SAVE = %w(install_dir version user group).freeze

        def service_name(resource)
          return nil unless resource.vsts_url
          hostname = URI.parse(resource.vsts_url).host
          hostname = hostname[0, hostname.index('.')] if hostname.include?('.')
          if windows?
            "vstsagent.#{hostname}.#{resource.agent_name}"
          else
            "vsts.agent.#{hostname}.#{resource.agent_name}"
          end
        end

        def service_config(resource)
          service_name = service_name(resource)
          if osx?
            "/Users/#{resource.user}/Library/LaunchAgents/#{service_name}.plist"
          else
            "/etc/systemd/system/#{service_name}.service"
          end
        end

        def archive_name(resource)
          name = 'vsts_build_agent'
          name += '_' + resource.version if resource.version
          name
        end

        def download_url(version, node)
          url = node['vsts_build_agent']['binary']['url']
          url = url.gsub '%s', version
          url
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

        def save_vars(resource, node)
          VARS_TO_SAVE.each { |var| node.set['vsts_build_agent']['agents'][resource.agent_name][var] = resource.send(var) if resource.respond_to?(var.to_sym) }
          node.save
        end

        def load_vars(resource, node)
          VARS_TO_SAVE.each { |var| resource.send(var, node['vsts_build_agent']['agents'][resource.agent_name][var]) if resource.respond_to?(var.to_sym) }
        end

        def load_current_state(resource, node)
          resource.exists = false
          if agent_attribute?(resource.agent_name, node)
            load_vars(resource, node)
            if ::File.exist?(::File.join(resource.install_dir, '.agent'))
              load_data_from_json(resource)
              resource.runasservice(::File.exist?(::File.join(resource.install_dir, '.service')))
              resource.exists = true
            end
          end
        end

        def load_data_from_json(resource)
          f = ::File.read(::File.join(resource.install_dir, '.agent'), :mode => 'r:bom|utf-8').strip
          agent = JSON.parse(f)
          resource.vsts_url(agent['serverUrl'])
          resource.vsts_pool(agent['poolName'])
          resource.work_folder(agent['workFolder'])
        end

        def agent_attribute?(agent_name, node)
          if node['vsts_build_agent']['agents'].nil? ||
             node['vsts_build_agent']['agents'][agent_name].nil? ||
             node['vsts_build_agent']['agents'][agent_name]['install_dir'].nil? ||
             node['vsts_build_agent']['agents'][agent_name]['install_dir'].empty?
            return false
          else
            return true
          end
        end

        def remove_current_state(resource, node)
          node.set['vsts_build_agent']['agents'][resource.agent_name] = {}
          node.save
        end

        def set_auth(args, resource)
          args['auth'] = resource.vsts_auth
          if resource.vsts_auth == 'PAT'
            args['token'] = resource.vsts_token
          elsif (resource.vsts_auth == 'Negotiate') || (resource.vsts_auth == 'ALT')
            args['--username'] = resource.vsts_username
            args['--password'] = resource.vsts_password
          end
        end

        def vsagentexec(args = {})
          command = 'Agent.Listener '
          command = './' + command unless windows?
          args.each { |key, value| command += append_arguments(key, value) + ' ' }
          command
        end

        def append_arguments(key, value)
          result = ''
          if key == 'configure' || key == 'remove'
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
end
