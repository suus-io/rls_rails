require_relative "../migration_generator"

class PolicyGenerator < ::Rails::Generators::NamedBase
  include ::Rails::Generators::Migration

  source_root File.expand_path('templates', __dir__)

  def create_policies_directory
    unless policy_path.exist?
      empty_directory(policy_path)
    end
  end

  def create_policy_definition
    if creating_new_policy?
      create_file policy_path(1), <<-RUBY
RLS.policies_for :#{plural_name} do  
  policy :my_policy do
    using <<-SQL
      -- your policy here
    SQL
  end
end
      RUBY
    else
      copy_file policy_path(version), policy_path(version+1)
    end
  end

  def create_migration_file
    if creating_new_policy? || destroying_initial_policy?
      migration_template(
          "db/migrate/create_policy.erb",
          "db/migrate/create_policy_for_#{plural_file_name}.rb",
          )
    else
      migration_template(
          "db/migrate/update_policy.erb",
          "db/migrate/update_policy_for_#{plural_file_name}_to_version_#{version}.rb",
          )
    end
  end

  no_tasks do
    def version
      dir_path = policy_path
      if Dir.exists? dir_path
        Dir.entries(dir_path).reject{|f| File.directory? f }.map{|n| n[-5..-4].to_i}.max || 0
      else
        0
      end
    end

    def previous_version
      version - 1
    end

    def migration_class_name
      if creating_new_policy?
        "CreatePolicyFor#{class_name.gsub('.', '').pluralize}"
      else
        "UpdatePolicyFor#{class_name.pluralize}ToVersion#{version}"
      end
    end
  end

  private

  def policy_directory_path
    @policy_directory_path ||= Rails.root.join(*%w(db policies))
  end

  def policy_path version = false
    path = policy_directory_path.join plural_name
    path = path.join "#{plural_name}_v#{sprintf('%02d', version)}.rb" if version
    path
  end

  def creating_new_policy?
    previous_version <= 0
  end

  def destroying?
    behavior == :revoke
  end

  def destroying_initial_policy?
    destroying? && version == 1
  end

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
