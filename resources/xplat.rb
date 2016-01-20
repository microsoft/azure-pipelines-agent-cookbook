actions :install, :remove, :restart
default_action :install

attribute :agent_name, :name_attribute => true
attribute :install_dir, :kind_of => String

attribute :user, :kind_of => String
attribute :group, :kind_of => String
attribute :user_home, :kind_of => String

attribute :sv_name, :kind_of => String # Default vsoagent.host.agent_name
attribute :sv_cookbook, :kind_of => String, :default => 'vsts_build_agent'
attribute :sv_template, :kind_of => String, :default => 'vsts_build_agent'
attribute :sv_timeout, :kind_of => Integer, :default => 120
attribute :sv_envs, :kind_of => Hash, :default => {}
attribute :sv_session, :kind_of => String, :default => nil # used by MacOsX. Can be Aqua for interact with GUI
attribute :sv_wait_timeout, :kind_of => Integer, :default => 5

attribute :vsts_url, :kind_of => String
attribute :vsts_pool, :kind_of => String
attribute :vsts_user, :kind_of => String
attribute :vsts_token, :kind_of => String

attr_accessor :exists
