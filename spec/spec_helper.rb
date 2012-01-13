require 'bundler'
Bundler.require

require 'sheldon-client'
require 'webmock/rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

if ENV['verbose']
  puts "Sheldon client in verbose mode"
  SheldonClient.log = true
end

RSpec.configure do |config|

end
