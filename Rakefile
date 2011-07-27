require 'rubygems'
require 'bundler'

require 'rake/gem_upload'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "sheldon-client"
  gem.homepage = "http://github.com/gozmo/sheldon-client"
  gem.license = "MIT"
  gem.summary = %Q{Talks to Sheldon}
  gem.description = %Q{The gem makes it possible to talk to sheldon using easy calls}
  gem.email = "core@moviepilot.com"
  gem.authors = ["Pontus Lindstrom", "Benjamin Krause"]
  gem.files = Dir['lib/**/*.rb']
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb'].exclude('spec/requests/*_spec.rb')
end

namespace :spec do
  RSpec::Core::RakeTask.new(:requests) do |spec|
    spec.pattern = 'spec/requests/*_spec.rb'
  end
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "sheldon-client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Loads a console with lib/sheldon-client.rb'
task :irb do
  exec("irb -Ilib -rsheldon-client")
end
