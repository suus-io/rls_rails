ENV['RAILS_ENV'] = 'test'

require File.expand_path("dummy/config/environment", __dir__)

require 'rubygems'
require 'active_record'

require 'bundler/setup'
Bundler.setup

require 'rls_rails' # and any other gems you need

RSpec.configure do |config|
  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"
end