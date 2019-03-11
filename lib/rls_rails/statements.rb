module RLS
  module Statements
    include RLS::Util

    def enable_rls table, force: false
      reversible do |dir|
        dir.up   { do_enable_rls  table, force: force }
        dir.down { do_disable_rls table, force: force }
      end
    end

    def disable_rls table, force: false
      reversible do |dir|
        dir.up   { do_disable_rls table, force: force }
        dir.down { do_enable_rls  table, force: force }
      end
    end

    def create_policy table, version: 1
      reversible do |dir|
        dir.up   { do_create_policy table, version: version }
        dir.down { do_drop_policy   table, version: version }
      end
    end

    def drop_policy table, version: nil
      reversible do |dir|
        dir.up   { do_drop_policy   table, version: version }
        dir.down { do_create_policy table, version: version }
      end
    end

    def update_policy table, version: nil, revert_to_version: nil
      RLS.clear_policies!

      reversible do |dir|
        dir.up do
          drop_policies_for table
          do_create_policy(table, version: version || last_version_of(table) + 1)
        end

        dir.down do
          new_version = revert_to_version || last_version_of(table) - 1
          raise ActiveRecord::IrreversibleMigration, 'update_policy: revert_to_version missing!' if revert_to_version.nil? && new_version > 0
          if new_version > 0
            do_drop_policy table, version: version
            do_create_policy table, version: new_version
          else
            do_drop_policy table, version: version
          end
        end
      end
    end

    private

    def drop_policies_for table
      existing_policies = execute("SELECT policyname FROM pg_policies WHERE tablename = '#{table}'").values.flatten
      existing_policies.each do |policy_name|
        execute "DROP POLICY #{policy_name} ON #{table};"
      end
    end

    def do_create_policy table, version: nil
      RLS.clear_policies!
      enable_rls table, force: true
      load policy_path(table, version)
      execute RLS.create_sql(table)
    end

    def do_drop_policy table, version: nil
      RLS.clear_policies!
      load policy_path(table, version || last_version_of(table))
      execute RLS.drop_sql(table)
    end

    def do_enable_rls table, force: false
      q = "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY#{force ? ', FORCE ROW LEVEL SECURITY' : ''};"
      execute q
    end

    def do_disable_rls table, force: false
      q = "ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY#{force ? ', NO FORCE ROW LEVEL SECURITY' : ''};"
      execute q
    end
  end
end