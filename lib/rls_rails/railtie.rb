require "rails"

module RLS
  def self.configure
    @configuration ||= Railtie.config.rls_rails
    yield @configuration if block_given?
  end

  class Railtie < ::Rails::Railtie
    config.rls_rails = ActiveSupport::OrderedOptions.new
    config.rls_rails.policy_dir = 'db/policies'
    config.rls_rails.tenant_class = nil
    config.rls_rails.user_class = nil
    config.rls_rails.tenant_fk = :tenant_id
    config.rls_rails.verbose = false

    initializer "rls_rails.load" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include RLS::Statements
        #ActiveRecord::Migration::CommandRecorder.include Scenic::CommandRecorder
        #ActiveRecord::SchemaDumper.prepend Scenic::SchemaDumper

        ActiveRecord::Base.connection.class.set_callback :checkout, :after do
          # ensure the RLS-related session variables are reset when a
          # thread checks out a connection
          execute <<~SQL
            RESET rls.user_id;
            RESET rls.tenant_id;
            RESET rls.disable;
          SQL

          clear_query_cache

          RLS.thread_rls_status.merge!(tenant_id: '', user_id: '', disabled: '')
        end
      end
    end

    rake_tasks do
      load 'rls_rails/tasks/init.rake'
      load 'rls_rails/tasks/recreate.rake'
    end
  end
end
