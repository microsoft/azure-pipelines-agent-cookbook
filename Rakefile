require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'cookstyle'
require 'foodcritic'
require 'kitchen'

namespace :style do
  desc 'Run cookstyle checks'
  RuboCop::RakeTask.new(:ruby) do |task|
    task.options << '--display-cop-names'
  end

  desc 'Run foodcritic checks'
  FoodCritic::Rake::LintTask.new(:chef)
end

namespace :kitchen do
  desc 'Run Test Kitchen with Vagrant'
  task :linux do
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.get('xplat-basic-ubuntu1404').test(:always)
  end
end

namespace :solo do
  desc 'Use chef-solo to bootstrap current node'
  task :install do
    exec 'berks installl'
  end

  task :vendor do
    exec 'berks vendor solo-cookbooks'
  end

  task :windows do
    Rake::Task['solo:install']
    Rake::Task['solo:vendor']
    exec 'chef-solo -c test\solo.rb -j test\cookbooks\windows-basic\solo.json'
  end
end

desc 'Run all style checks'
task style: ['style:chef', 'style:ruby']

desc 'Run ChefSpec'
RSpec::Core::RakeTask.new(:spec)

task :supermarket do
  exec 'chef exec knife supermarket share vsts_agent Other -o .. -k supermarket.pem -u vsts_agent_cookbook'
end

task default: ['style', 'kitchen:linux']

task travis: ['style']

task release: ['supermarket']
