Visual Studio Team Services Build Agent Cookbook
================

[![Join the chat at https://gitter.im/Microsoft/vsts-build-agent-cookbook](https://badges.gitter.im/Microsoft/vsts-build-agent-cookbook.svg)](https://gitter.im/Microsoft/vsts-build-agent-cookbook?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/Microsoft/vsts-build-agent-cookbook.svg?branch=master)](https://travis-ci.org/Microsoft/vsts-build-agent-cookbook)
[![Cookbook Version](https://img.shields.io/cookbook/v/vsts_build_agent.svg)](https://supermarket.chef.io/cookbooks/vsts_build_agent)

Installs and configures Visual Studio Team Services [Build Agent](https://www.visualstudio.com/en-us/get-started/build/build-your-app-vs) (a.k.a VSO Build Agent)

Requirements
------------
- Chef 11 or higher

### Platforms
The following platforms are tested and supported:
- Debian 7 (Wheezy)
- Ubuntu 14.04
- CentOS 6
- Windows 8.1
- Windows 10
- Mac OS X 10.9.5

The following platforms are known to work:
- Microsoft Windows (8, 8.1, 10)

### Dependent Cookbooks
This cookbook doesn't install nodejs executables for an XPlat(CrossPlatform) build agent.
Please use [nodejs](https://supermarket.chef.io/cookbooks/nodejs) cookbook or any other ways which suits your case.

Attributes
----------

* `node['vsts_build_agent']['xplat']['package_name']` - Set an xplat build agent [npm](https://www.npmjs.com/package/vsoagent-installer) package name
* `node['vsts_build_agent']['xplat']['package_version']` - Set an npm package version. Possible values 'x.y.z' or 'latest'
* `node['vsts_build_agent']['xplat']['skip_vsoagent_installer']` - Set to 'true' if you need another way to install npm package.

Resource/Provider
-----------------
### windows
This resource installs and configures a build agent on windows host
#### Actions
- `:install`: Install and configure a build agent
- `:remove`: Remove a build agent and unregister it from VSTS
- `:restart`: Restart a build agent service

#### Parameters
- `agent_name`: Name attribute. The name of a build agent
- `install_dir`: A target directory to install a build agent
- `sv_name`: Set a windows service name. Default vsoagent.host.agent_name
- `sv_user`: Set a user name to run windows service. Possible values are "NT AUTHORITY\\NetworkService", "NT AUTHORITY\\LocalService" or any system valid username
- `sv_password`: Set password with sv_user unless it is equal to NetworkService or LocalService
- `vsts_url`: A target VSTS url
- `vsts_user`: A user to connect with VSTS
- `vsts_token`: A personal access token from VSTS. [See](http://roadtoalm.com/2015/07/22/using-personal-access-tokens-to-access-visual-studio-online/)
- `vsts_pool`: A pool name on VSTS
- `work_folder`: Set different workspace location. Default is "install_dir/\_work"

#### Examples
Install, configure, restart and remove a build agent.
Check [tests](test/cookbooks/windows-basic/recipes/default.rb) for more examples.

```ruby
include_recipe 'vsts_build_agent::default'

vsts_build_agent_windows 'agent' do
  install_dir 'c:\\agents\\agent1'
  sv_user 'vagrant'
  sv_password 'vagrant'
  vsts_url 'https://<account>.visualstudio.com'
  vsts_pool 'default'
  vsts_user 'builder'
  vsts_token 'my_secret_token_from_vsts'
  action :install
end

vsts_build_agent_windows 'agent' do
  action :restart
end

vsts_build_agent_windows 'agent' do
  vsts_token 'my_secret_token_from_vsts'
  action :remove
end
```

### xplat
This resource installs and configures a build agent on linux or macosx host
#### Actions
- `:install`: Install and configure a build agent
- `:remove`: Remove a build agent and unregister it from VSTS
- `:restart`: Restart a build agent service

#### Parameters
- `agent_name`: Name attribute. The name of build agent
- `install_dir`: A target directory to install build agent
- `user`: Set a user to run build agent.
- `group`: Set a group to run build agent.
- `sv_name`: Set a service name. Default vsoagent.host.agent_name
- `sv_envs`: Set hash of environment variables to pass into an agent process
- `sv_session`: For MacOsX only. Set a LaunchAgent session.
- `vsts_url`: A target VSTS url
- `vsts_user`: A user to connect with VSTS
- `vsts_token`: A personal access token from VSTS. [See](http://roadtoalm.com/2015/07/22/using-personal-access-tokens-to-access-visual-studio-online/)
- `vsts_pool`: A pool name on VSTS

#### Examples
Install, configure, restart and remove build agent.
Check [tests](test/cookbooks/xplat-basic/recipes/default.rb) for more examples.

```ruby
include_recipe 'vsts_build_agent::default'

if platform_family?('mac_os_x')
  include_recipe 'homebrew'
end

include_recipe 'nodejs::default'
include_recipe 'nodejs::npm'

vsts_build_agent_xplat 'xplat_agent' do
  install_dir "/home/vagrant/agents/xplat_agent"
  user 'vagrant'
  group 'vagrant'
  sv_envs(
    'PATH' => '/usr/local/bin/:/opt/local/bin:/sbin:/usr/sbin:/bin:/usr/bin',
    'TEST' => 'agent1'
    )
  vsts_url 'https://account.visualstudio.com'
  vsts_pool 'default'
  vsts_user 'builder'
  vsts_token 'my_secret_token_from_vsts'
  action :install
end

vsts_build_agent_xplat 'xplat_agent' do
  action :restart
end

vsts_build_agent_xplat 'xplat_agent' do
  vsts_token 'my_secret_token_from_vsts'
  action :remove
end
```

# How to contribute
Check [Contribution Guide](CONTRIBUTING.md) and [Testing Guide](TESTING.md)
