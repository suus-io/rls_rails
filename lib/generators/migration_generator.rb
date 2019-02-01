require "rails/generators"
require "rails/generators/active_record"

module RlsRails
  # Basic structure to support a generator that builds a migration
  class MigrationGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    protected

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    def activerecord_migration_class
      if ActiveRecord::Migration.respond_to?(:current_version)
        "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
      else
        "ActiveRecord::Migration"
      end
    end
  end
end