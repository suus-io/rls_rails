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
        drops = execute(q).values.map(&:first).join("\n")
        execute drops
      end
    end

    def create_all_policies
      path = RLS::Railtie.config.rls[:policy_dir]
      folders = Dir.entries(path).select{|f| File.directory?(path+'/'+f) && f[0] != '.'}
      folders.each do |table|
        q = "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY; ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;"
        execute q
        version =  last_version_of(table)
        load policy_path(table, version)
        execute RLS.create_sql(table)
      end
    end

    def execute q
      ActiveRecord::Base.connection.execute q
    end
  end
end