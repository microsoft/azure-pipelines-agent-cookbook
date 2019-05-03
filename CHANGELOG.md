# Azure Pipelines Agent Cookbook Changelog

## [v3.0.1](https://github.com/Microsoft/azure-pipelines-agent-cookbook/tree/v3.0.1) - (2018-09-29)

### Removed

- Remove require of `chef/mixin/language`

  This mixin was removed from Chef 14. See [this stackoverflow](https://stackoverflow.com/questions/49909084/cannot-load-such-file-chef-mixin-language)

  Fixes following compile error in Chef 14.3.37:

  ```ruby
  ================================================================================
  Recipe Compile Error in /tmp/kitchen/cache/cookbooks/vsts_agent/libraries/service.rb
  ================================================================================
  LoadError
  ---------
  cannot load such file -- chef/mixin/language

  Cookbook Trace:
  ---------------
  /tmp/kitchen/cache/cookbooks/vsts_agent/libraries/service.rb:4:in '<top (required)>'

  Relevant File Content:
  ----------------------
  /tmp/kitchen/cache/cookbooks/vsts_agent/libraries/service.rb:

    1:  require 'chef/resource/lwrp_base'
    2:  require 'chef/provider/lwrp_base'
    3:  require 'chef/mixin/shell_out'
    4>> require 'chef/mixin/language'
    5:
    6:  module VSTS
    7:    module Agent
    8:      # The service operations for vsts_agent
    9:      class Service
  10:        include Windows::Helper
  11:        include VSTS::Agent::Helpers
  12:        include Chef::DSL::PlatformIntrospection
  13:

  System Info:
  ------------
  chef_version=14.3.37
  platform=debian
  platform_version=8.11
  ruby=ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux]
  program_name=/opt/chef/bin/chef-client
  executable=/opt/chef/bin/chef-client

  Running handlers:
  [2018-08-17T17:57:39-07:00] ERROR: Running exception handlers
  [2018-08-17T17:57:39-07:00] ERROR: Running exception handlers
  Running handlers complete
  [2018-08-17T17:57:39-07:00] ERROR: Exception handlers complete
  [2018-08-17T17:57:39-07:00] ERROR: Exception handlers complete
  Chef Client failed. 0 resources updated in 01 seconds
  [2018-08-17T17:57:39-07:00] FATAL: Stacktrace dumped to /tmp/kitchen/cache/chef-stacktrace.out
  [2018-08-17T17:57:39-07:00] FATAL: Stacktrace dumped to /tmp/kitchen/cache/chef-stacktrace.out
  [2018-08-17T17:57:39-07:00] FATAL: Please provide the contents of the stacktrace.out file if you file a bug report
  [2018-08-17T17:57:39-07:00] FATAL: Please provide the contents of the stacktrace.out file if you file a bug report
  [2018-08-17T17:57:39-07:00] FATAL: LoadError: cannot load such file -- chef/mixin/language
  [2018-08-17T17:57:39-07:00] FATAL: LoadError: cannot load such file -- chef/mixin/language
  ```

  Closed #32

### Changed

- `build-essential::default` is broken in `8.1.1`. Implemented resource in place of recipe.

### Added

- Add missing installation of **7zip**.
- Copy `win_friendly_path` method to helpers library.
- Add Windows Server 2016 to kitchen.yml

## [v3.0.0](https://github.com/Microsoft/azure-pipelines-agent-cookbook/tree/v3.0.0) - (2018-08-05)

### Added

- Add deployment groups support. Closed #27
