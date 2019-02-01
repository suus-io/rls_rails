namespace :rls_rails do
  desc 'Initializes rls_rails by generating policy-files from existing policies in the database.'
  task :init do
    dump = File.read("db/structure.sql")
    with_check_regex = /CREATE POLICY (.*) ON ((.*\.)?(.*)) USING \(([^;]*)\) WITH CHECK \(([^;]*)\);/i
    only_using_regex = /CREATE POLICY (.*) ON ((.*\.)?(.*)) USING \((([^;](?! WITH CHECK))*)\);/i

    policies = {}
    dump.scan(only_using_regex).each do |match|
      policy_name, schema_table, schema, table, using, _ = match
      (policies[table] ||= {})[policy_name] = { using: using, check: false }
    end

    dump.scan(with_check_regex).each do |match|
      policy_name, schema_table, schema, table, using, check = match
      (policies[table] ||= {})[policy_name] = { using: using, check: false }
    end

    policies.each do |table, pols|
      save_policies table, pols
    end
  end

  def save_policies table, policies
    dir_path = policy_path(table)
    Dir.mkdir(dir_path) unless Dir.exists? dir_path
    path = policy_path(table, 1)
    puts "Init policy #{path}"

    File.open(path, 'w') do |f|
      str =  "RLS.policies_for(:#{table}) do\n"

      policies.each do |policy_name, data|
        str << "\n  policy(:#{policy_name}) do\n"
        str << "    using <<-SQL\n#{data[:using].split("\n").map{|l| "      "+l}.join("\n")}\n    SQL\n" if data[:using]
        str << "    check <<-SQL\n#{data[:check].split("\n").map{|l| "      "+l}.join("\n")}\n    SQL\n" if data[:check]
        str << "  end\n"
      end
      str << "end\n"

      f.write str
    end
  end
end