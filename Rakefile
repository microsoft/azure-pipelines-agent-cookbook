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
