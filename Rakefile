begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ContextualizedLogs'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'bundler/gem_tasks'
require "rspec/core/rake_task"

desc "Play a demo of contextualized_logs"
task :demo do
  prompt = TTY::Prompt.new
  if `which asciinema`.empty?
    if `which brew`.empty
      return unless prompt.yes?('Install brew')
      `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`

      return unless prompt.yes?('Install asciinema using brew?')
      `brew install asciinema`
    end
  end
  prompt.warn('press [space] continuesly to play demo line by line, or just press [space] to play')
  exec('asciinema play -i 1 -s 1 demo.cast')
end


task :default => :spec
# # Add your own tasks in files placed in lib/tasks ending in .rake,
# # for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
#
require_relative 'config/application'
#
Rails.application.load_tasks
