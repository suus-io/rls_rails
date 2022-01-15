ENV['RAILS_ENV'] = 'test'

require File.expand_path("dummy/config/environment", __dir__)

require 'rubygems'
require 'active_record'

require 'bundler/setup'
Bundler.setup

require 'rls_rails' # and any other gems you need

RSpec.configure do |config|
  # some (optional) config here
end