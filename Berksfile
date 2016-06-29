source 'https://supermarket.chef.io'

cookbook 'ark', git: 'git://github.com/ivadim/ark.git'

metadata

group :integration do
  cookbook 'debian-basic', :path => './test/cookbooks/debian-basic'
  cookbook 'windows-basic', :path => './test/cookbooks/windows-basic'
  cookbook 'osx-basic', :path => './test/cookbooks/osx-basic'
end
