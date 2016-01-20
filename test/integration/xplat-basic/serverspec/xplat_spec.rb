require 'serverspec'

set :backend, :exec

if os[:family] == 'darwin'
  home_dir = '/Users/vagrant'
else
  home_dir = '/home/vagrant'
end

describe file("#{home_dir}/agents/agent_01/.agent") do
  it { should_not exist }
end

describe file("#{home_dir}/agents/agent_02/.agent") do
  it { should be_file }
end

describe service('agent2'), :unless => os[:family] == 'darwin' do
  it { should be_running }
end
