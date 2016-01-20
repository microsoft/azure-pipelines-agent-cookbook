require 'serverspec'

set :backend, :cmd
set :os, :family => 'windows'

describe file('c:\\agents\\agent_01\\Agent\\VsoAgent.exe') do
  it { should be_file }
end

describe file('c:\\agents\\agent_02\\Agent\\VsoAgent.exe') do
  it { should be_file }
end

describe file('c:\\agents\\agent_03\\Agent\\VsoAgent.exe') do
  it { should_not be_file }
end

describe service('agent_02.service') do
  it { should be_running }
end
