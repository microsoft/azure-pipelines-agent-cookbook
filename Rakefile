require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'foodcritic'
require 'kitchen'

namespace :style do
  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:ruby)

  desc 'Run Chef style checks'
  FoodCritic::Rake::LintTask.new(:chef)
end

desc 'Run all style checks'
task :style => ['style:chef', 'style:ruby']

desc 'Run ChefSpec'
RSpec::Core::RakeTask.new(:spec)

namespace :kitchen do
  desc 'Run Test Kitchen with Vagrant'
  task :linux do
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.get('xplat-basic-ubuntu1404').test(:always)
  end
end

task :supermarket do
  exec 'chef exec knife supermarket share vsts_agent Other -o .. -k supermarket.pem -u vsts_agent_cookbook'
end

task :default => ['style', 'kitchen:linux']

task :travis => ['style']

task :release => ['supermarket']
