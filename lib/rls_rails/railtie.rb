require "rails"

module RLS
  class Railtie < ::Rails::Railtie
    config.rls = ActiveSupport::OrderedOptions.new
    config.rls.policy_dir = 'db/policies'

    initializer "rls_rails.load" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include RLS::Statements
        #ActiveRecord::Migration::CommandRecorder.include Scenic::CommandRecorder
        #ActiveRecord::SchemaDumper.prepend Scenic::SchemaDumper
      end
    end

    rake_tasks do
      load 'rls_rails/tasks/init.rake'
      load 'rls_rails/tasks/recreate.rake'
    end
  end
end
