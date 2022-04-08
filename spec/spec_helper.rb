ENV['RAILS_ENV'] = 'test'

require File.expand_path("dummy/config/environment", __dir__)

require 'rubygems'
require 'active_record'

require 'bundler/setup'
Bundler.setup

require 'rls_rails' # and any other gems you need

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/dummy/config/database.yml'))
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

  ActiveRecord::Base.establish_connection #(config[db_adapter])
  load(File.dirname(__FILE__) + "/dummy/db/schema.rb")
end

load_schema

RSpec.configure do |config|
  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"
end