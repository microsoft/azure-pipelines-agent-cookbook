
if platform_family?('debian') && node['vsts_agent']['prerequisites']['debian']['install']

  %w(libunwind8 liblttng-ust0 libcurl3 libuuid1 libkrb5-3 zlib1g).each do |pkg|
    package pkg
  end

  package 'libssl1.0.0' unless node['platform_version'] =~ /^9.*/
  package 'libssl1.0.2' if node['platform_version'] =~ /^9.*/
  package 'libicu52' if node['platform_version'] =~ /^14.*/ || node['platform_version'] =~ /^8.*/
  package 'libicu55' if node['platform_version'] =~ /^16.*/
  package 'libicu57' if node['platform_version'] =~ /^17.*/ || node['platform_version'] =~ /^9.*/

elsif platform_family?('rhel') && node['vsts_agent']['prerequisites']['redhat']['install']

  %w(libunwind libcurl openssl-libs libuuid krb5-libs libicu zlib).each do |pkg|
    package pkg
  end

end
