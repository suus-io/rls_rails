module RLS
  module Statements
    def enable_rls table, force: false
      reversible do |dir|
        dir.up do
          q = "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY#{force ? ', FORCE ROW LEVEL SECURITY' : ''};"
          execute q
        end

        dir.down do
          q = "ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY;"
          execute q
        end
      end
    end

    def create_policy table, version: 1
      RLS.clear_policies!
      reversible do |dir|
        dir.up do
          enable_rls table, force: true
          load policy_path(table, version)
          execute RLS.create_sql(table)
        end

        dir.down do
          drop_policy table, version: version
        end
      end
    end

    def drop_policy table, version: nil
      RLS.clear_policies!

      reversible do |dir|
        dir.up do
          load policy_path(table, version || last_version_of(table))
          execute RLS.drop_sql(table)
        end

        dir.down do
          create_policy table, version: version
        end
      end
    end

    def update_policy table, version: nil, revert_to_version: nil
      RLS.clear_policies!

      reversible do |dir|
        dir.up do
          # Drop existing policies
          existing_policies = execute("SELECT policyname FROM pg_policies WHERE tablename = '#{table}'").values.flatten
          existing_policies.each do |policy_name|
            execute("DROP POLICY  #{policy_name} ON #{table};")
          end

          # Create current policies
          file = version ? policy_path(table, version) : policy_path(table, last_version_of(table) + 1)
          load(file)
          sql = RLS.create_sql(table)
          puts sql
          execute sql
        end

        dir.down do
          version = revert_to_version || last_version_of(table) - 1
          raise ActiveRecord::IrreversibleMigration, 'update_policy: revert_to_version missing!' if revert_to_version.nil? && version > 0
          file = policy_path(table, version)
          load(file)
          if version > 0
            execute RLS.create_sql(table)
          else
            execute RLS.drop_sql(table)
          end
        end
      end
    end
  end
end