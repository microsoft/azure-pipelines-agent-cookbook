

module VSTS
  module Build
    module Agent
      # Helper methods for VSTS Build Agent installation
      module Helpers
        VARS_TO_SAVE = %w(vsts_url vsts_pool vsts_user install_dir sv_name sv_session user group user_home).freeze

        def agent_installed?(resource, node)
          agent_attribute?(resource.agent_name, node) &&
            (::File.exist?("#{resource.install_dir}/.agent") ||
             ::File.file?("#{resource.install_dir}\\Agent\\VsoAgent.exe"))
        end

        def service_name(resource)
          return resource.sv_name if resource.sv_name
          return nil unless resource.vsts_url
          hostname = URI.parse(resource.vsts_url).host
          hostname = hostname[0, hostname.index('.')] if hostname.include?('.')
          "vsoagent.#{hostname}.#{resource.agent_name}"
        end

        def get_npm_install_cmd(node)
          npm_cmd = "npm install -global #{node['vsts_build_agent']['xplat']['package_name']}"
          unless node['vsts_build_agent']['xplat']['package_version'] == 'latest'
            npm_cmd += "@#{node['vsts_build_agent']['xplat']['package_version']}"
          end
          npm_cmd
        end

        def save_current_state(resource, node)
          VARS_TO_SAVE.each do |var|
            node.set['vsts_build_agent']['agents'][resource.agent_name][var] = resource.send(var) if resource.respond_to?(var.to_sym)
          end
          node.save
        end

        def load_current_state(resource, node)
          return unless agent_attribute?(resource.agent_name, node)
          VARS_TO_SAVE.each do |var|
            resource.send(var, node['vsts_build_agent']['agents'][resource.agent_name][var]) if resource.respond_to?(var.to_sym)
          end
        end

        def agent_attribute?(agent_name, node)
          node['vsts_build_agent']['agents'] && node['vsts_build_agent']['agents'][agent_name]
        end

        def remove_current_state(resource, node)
          node.set['vsts_build_agent']['agents'][resource.agent_name] = {}
          node.save
        end

        def plist_path(resource)
          path = if resource.sv_session
                   "/Library/LaunchAgents/#{resource.sv_name}.plist"
                 else
                   "/Library/LaunchDaemons/#{resource.sv_name}.plist"
                 end

          path = "#{resource.user_home}#{path}" if resource.user_home
          path
        end

        def launchctl_load(resource)
          plist = plist_path resource
          command = 'launchctl load -w '
          command += "-S #{resource.sv_session} " if resource.sv_session
          command += plist
          command
        end

        def launchctl_unload(resource)
          plist = plist_path resource
          command = "launchctl unload #{plist}"
          command
        end

        def vsagentexec(args = {})
          command = 'Agent\\VsoAgent.exe '
          args.each do |key, value|
            command += "/#{key}"
            command += ":\"#{value}\"" unless value.nil?
            command += ' '
          end
          command
        end
      end
    end
  end
end
