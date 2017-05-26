actions :install, :remove, :restart
default_action :install

attribute :agent_name, name_attribute: true
attribute :install_dir, kind_of: String

attribute :user, kind_of: String
attribute :group, kind_of: String

attribute :work_folder, kind_of: String, default: '_work'

attribute :runasservice, kind_of: [TrueClass, FalseClass], default: true
attribute :windowslogonaccount, kind_of: String
attribute :windowslogonpassword, kind_of: String

# environment
attribute :version, kind_of: String
attribute :path, kind_of: String
attribute :env, kind_of: Hash, default: {}

# VSTS Access
attribute :vsts_url, kind_of: String
attribute :vsts_pool, kind_of: String
attribute :vsts_auth, kind_of: String, default: 'PAT'
attribute :vsts_username, kind_of: String
attribute :vsts_password, kind_of: String
attribute :vsts_token, kind_of: String

attr_accessor :exists
