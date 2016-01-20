actions :install, :remove, :restart
default_action :install

attribute :agent_name, :name_attribute => true
attribute :install_dir, :kind_of => String

attribute :sv_name, :kind_of => String
attribute :sv_user, :kind_of => String
attribute :sv_password, :kind_of => String

attribute :vsts_url, :kind_of => String
attribute :vsts_pool, :kind_of => String
attribute :vsts_user, :kind_of => String
attribute :vsts_token, :kind_of => String

attribute :work_folder, :kind_of => String, :default => '_work' # not supported on client side

attr_accessor :exists
