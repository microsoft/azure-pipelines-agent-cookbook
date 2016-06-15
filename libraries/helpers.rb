module VSTS
  module Build
    module Agent
      # Helper methods for VSTS Build Agent installation
      module Helpers
        include Chef::DSL::PlatformIntrospection
        
        require 'json'
        
        # def agent_installed?(resource, node) 
        #   agent_attribute?(resource.agent_name, node) && (::File.exist?("#{resource.install_dir}/.Agent"))
        # end
        
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
        
        def archive_name(resource)
          name = "vsts_build_agent"
          name += "_" + resource.version if resource.version
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
        
        def mac_os_x?
          platform_family?('mac_os_x') || platform_family?('mac_os_x_server')
        end

        def save_current_state(resource, node)
          node.set['vsts_build_agent']['agents'][resource.agent_name]['install_dir'] = resource.install_dir
          node.save
        end

        def load_current_state(resource, node)
          resource.exists = false
          return unless agent_attribute?(resource.agent_name, node)
          resource.install_dir(node['vsts_build_agent']['agents'][resource.agent_name]['install_dir']) unless resource.install_dir
          return unless ::File.exist?(::File.join(resource.install_dir, '.agent'))
          f = ::File.read(::File.join(resource.install_dir, '.agent'), mode: 'r:bom|utf-8').strip
          agent = JSON.parse(f)
          resource.vsts_url(agent['serverUrl'])
          resource.vsts_pool(agent['poolName'])
          resource.work_folder(agent['workFolder'])
          resource.exists = true
        end

        def agent_attribute?(agent_name, node)
          if node['vsts_build_agent']['agents'] != nil && 
              node['vsts_build_agent']['agents'][agent_name] != nil &&
              node['vsts_build_agent']['agents'][agent_name]['install_dir'] != nil &&
              !node['vsts_build_agent']['agents'][agent_name]['install_dir'].empty?
            return true
          else
            return false
          end
        end

        def remove_current_state(resource, node)
          node.set['vsts_build_agent']['agents'][resource.agent_name] = {}
          node.save
        end

        # def plist_path(resource)
        #   path = if resource.sv_session
        #            "/Library/LaunchAgents/#{resource.sv_name}.plist"
        #          else
        #            "/Library/LaunchDaemons/#{resource.sv_name}.plist"
        #          end

        #   path = "#{resource.user_home}#{path}" if resource.user_home
        #   path
        # end

        # def launchctl_load(resource)
        #   plist = plist_path resource
        #   command = 'launchctl load -w '
        #   command += "-S #{resource.sv_session} " if resource.sv_session
        #   command += plist
        #   command
        # end

        # def launchctl_unload(resource)
        #   plist = plist_path resource
        #   command = "launchctl unload #{plist}"
        #   command
        # end

        def vsagentexec(args = {})
          command = 'Agent.Listener '
          command = './' + command unless windows?
          args.each do |key, value|
            if key == 'configure' || key == 'remove'
              command += key
            else
              command += "--#{key}"
              command += " \"#{value}\"" unless value.nil?
            end
            command += ' '
          end
          command
        end
      end
    end
  end
end
