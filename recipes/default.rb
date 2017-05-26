if platform_family?('debian') && node['vsts_agent']['prerequisites']['debian']['install']
  package 'libunwind8'
  package 'libcurl3'
  unless platform?('ubuntu') && node['platform_version'].to_i >= 16
    package 'libicu52'
  end

elsif platform_family?('mac_os_x') || platform_family?('mac_os_x_server') && node['vsts_agent']['prerequisites']['osx']['install']

  include_recipe 'homebrew'

  package 'openssl' # Reference: https://www.microsoft.com/net/core#macos

  execute 'configure brew-installed openssl' do
    command 'mkdir -p /usr/local/lib/'
    action :run
  end

  execute 'link libcrypto dylib' do
    command 'ln -sf /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib /usr/local/lib/'
    action :run
  end

  execute 'link libssl dylib' do
    command 'ln -sf /usr/local/opt/openssl/lib/libssl.1.0.0.dylib /usr/local/lib/'
    action :run
  end
end
