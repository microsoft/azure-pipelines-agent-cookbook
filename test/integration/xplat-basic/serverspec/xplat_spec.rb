require 'serverspec'

set :backend, :exec

# home_dir = if os[:family] == 'darwin'
#              '/Users/vagrant'
#            else
#              '/home/vagrant'
#            end

# describe file("#{home_dir}/agents/agent_01/.agent") do
#   it { should_not exist }
# end

# describe file("#{home_dir}/agents/agent_02/.agent") do
#   it { should be_file }
# end

# describe service('agent2'), :unless => os[:family] == 'darwin' do
#   it { should be_running }
# end
