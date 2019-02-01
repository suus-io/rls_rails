require_relative "../migration_generator"

module RlsRails
  class InstallGenerator < MigrationGenerator

    source_root File.expand_path('templates', __dir__)

    def create_migration_file
      migration_template(
          "db/migrate/create_rls_functions.erb",
          "db/migrate/create_rls_functions.rb",
      )
    end

    def create_initializer
      initializer "rls_rails.rb", <<-RUBY
RLS.configure do |config|
  config.rls_rails.tenant_class = Tenant
  config.rls_rails.tenant_fk = :tenant_id
  config.rls_rails.policy_dir = 'db/policies'
end
      RUBY
    end
  end
end
