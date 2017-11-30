Visual Studio Team Services Build and Release Agent Cookbook
================

[![Join the chat at https://gitter.im/Microsoft/vsts-agent-cookbook](https://badges.gitter.im/Microsoft/vsts-agent-cookbook.svg)](https://gitter.im/Microsoft/vsts-agent-cookbook?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/Microsoft/vsts-agent-cookbook.svg?branch=master)](https://travis-ci.org/Microsoft/vsts-agent-cookbook)
[![Cookbook Version](https://img.shields.io/cookbook/v/vsts_agent.svg)](https://supermarket.chef.io/cookbooks/vsts_agent)

Installs and configures Visual Studio Team Services [Build and Release Agent](https://github.com/Microsoft/vsts-agent/)

Please check [Wiki](https://github.com/Microsoft/vsts-agent-cookbook/wiki) for more examples

Requirements
------------
- Chef 12.5.0 or higher

### Platforms
The following platforms are tested and supported:
- Debian 8 x64 (Jessie)
- Debian 9 x64 (Stretch)
- Ubuntu 16.04 (Xenial Xerus)
- Ubuntu 17.10 (Artful Aardvark)
- CentOS 7
- Windows 10
- Windows Server 2012 R2
- OS X 10.10.5
- OS X 10.11.4

Attributes
----------
* `node['vsts_agent']['binary']['version']` - set version of package to install
* `node['vsts_agent']['prerequisites']['redhat']['install']` - control dependencies installation for redhat based distros(redhat, centos etc.) . Default true
* `node['vsts_agent']['prerequisites']['debian']['install']` - control dependencies installation for debian based distros(debian, ubuntu etc.). Default true

Resource/Provider
-----------------
### vsts_agent
This resource installs and configures the vsts build and release agent
#### Actions
- `:install`: Install and configure the agent
- `:remove`: Remove the agent and unregister it from VSTS
- `:restart`: Restart the agent service

#### Parameters
- `agent_name`: Name attribute. The name of the vsts agent
- `version`: an agent version to install. Default version from an attribute
- `install_dir`: A target directory to install the vsts agent
- `path`: Overwrite system PATH environment variable values. Linux and macOS only
- `env`: Additional environment variables. Linux and macOS only
- `user`: Set a local user to run the vsts agent
- `group`: Set a local group to run the vsts agent
- `runasservice`: run agent as a service. Default 'true'
- `windowslogonaccount`: Set a user name to run a windows service. Possible values are "NT AUTHORITY\NetworkService", "NT AUTHORITY\LocalService" or any system valid username
- `windowslogonpassword`: Set password for windowslogonaccount unless it is equal to NetworkService or LocalService
- `vsts_url`: url to VSTS instance
- `vsts_pool`: A pool to connect an agent
- `vsts_auth`: Authentication type. Default PAT auth. Valid options are:
  * PAT - Personal Access Token (requires vsts_token),
  * Negotiate - Kerberos or NTLM (requires vsts_username and vsts_password),
  * ALT - Alternate Credentials (requires vsts_username and vsts_password),
  * Integrated - Windows default credentials (doesn't require any credentials).
- `vsts_token`: A personal access token for VSTS. Used with PAT auth type. [See](http://roadtoalm.com/2015/07/22/using-personal-access-tokens-to-access-visual-studio-online/)
- `vsts_username`: A user to connect to VSTS. Used with Negotiate and ALT auth
- `vsts_password`: A user to connect to VSTS. Used with Negotiate and ALT auth
- `work_folder`: Set different workspace location. Default is "install_dir/\_work"

#### Examples
Install, configure, restart and remove an agent.
Check [windows](test/cookbooks/windows-basic/recipes/default.rb), [linux](test/cookbooks/linux-basic/recipes/default.rb) or [osx](test/cookbooks/osx-basic/recipes/default.rb) tests for more examples.

```ruby
include_recipe 'vsts_agent::default'

if platform_family?('windows')
  dir = 'c:\\agents'
else
  dir = '/tmp/agents'
end

vsts_agent 'agent_01' do
  install_dir dir
  user 'vagrant'
  group 'vagrant'
  path '/usr/local/bin/:/usr/bin:/opt/bin/' # only works on nix systems
  env('M2_HOME' => '/opt/maven', 'JAVA_HOME' => '/opt/java') # only works on nix systems
  vsts_url 'https://contoso.visualstudio.com'
  vsts_pool 'default'
  vsts_token 'my_secret_token_from_vsts'
  windowslogonaccount 'builder' # will be used only on windows
  windowslogonpassword 'Pas$w0r_d' # will be used only on windows
  action :install
end

vsts_agent 'agent_01' do
  action :restart
end

vsts_agent 'agent_01' do
  vsts_token 'my_secret_token_from_vsts'
  action :remove
end
```

# How to contribute
Check [Contribution Guide](CONTRIBUTING.md) and [Testing Guide](TESTING.md)
