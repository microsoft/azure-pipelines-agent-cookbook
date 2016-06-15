include_recipe 'ark::default'

if platform_family?('debian')
  package 'libunwind8' do
    action :install
  end
end