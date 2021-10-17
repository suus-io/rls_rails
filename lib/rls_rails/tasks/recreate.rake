namespace :db do
  namespace :policies do
    desc 'Delete all existing policies and recreate from db/policies with latest version'
    task :recreate => :environment do
      delete_all_policies
      create_all_policies
    end

    include RLS::Util

    def delete_all_policies
      q = "SELECT 'DROP POLICY ' || policyname  || ' ON ' || tablename || ';' FROM pg_policies WHERE schemaname='public';"
      ActiveRecord::Base.transaction do
        drops = execute_q(q).values.flatten.join("\n")
        execute_q drops
      end
    end

    def create_all_policies
      path = RLS::Railtie.config.rls_rails[:policy_dir]
      folders = Dir.entries(path).select{|f| File.directory?(path+'/'+f) && f[0] != '.'}
      folders.each do |table|
        q = "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY;"
        execute_q q
        version = last_version_of(table)
        load policy_path(table, version)
        execute_q RLS.create_sql(table)
      end
    end

    def execute_q q
      ActiveRecord::Base.connection.execute_q q
    end
  end
end
