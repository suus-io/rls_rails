require "rls/railtie"
require 'helpers'
require 'dsl'
require 'statements'
module RLS
  # Hooks RLS into Rails.
  #
  # Enables policy migration methods[, migration reversability, and `schema.rb` dumping.]
  def self.load
    ActiveRecord::ConnectionAdapters::AbstractAdapter.include RLS::Statements
    #ActiveRecord::Migration::CommandRecorder.include Scenic::CommandRecorder
    #ActiveRecord::SchemaDumper.prepend Scenic::SchemaDumper
  end
end
