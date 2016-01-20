if %w(debian rhel fedora gentoo).include?(node['platform_family'])
  include_recipe 'runit::default'
end
