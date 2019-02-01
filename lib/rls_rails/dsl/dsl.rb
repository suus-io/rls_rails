require 'rls_rails/dsl/policy'
require 'rls_rails/dsl/policy_factory'

module RLS
  def self.policies
    @@policies ||= {}
    @@policies
  end

  def self.create_sql(table)
    tbl_policies = self.policies[table.to_sym].values
    if tbl_policies.none?(&:permissive?) && tbl_policies.any?(&:restrictive?)
      raise "#{table.to_s}: Restrictive policies may only be used if at least one permissive policy is present!"
    end
    tbl_policies.map(&:to_create_sql).join("\n\n\n")
  end

  def self.clear_policies!
    @@policies = {}
  end

  def self.drop_sql(table)
    self.policies[table.to_sym].values.map(&:to_drop_sql).join("\n\n\n")
  end

  def self.policies_for(tbl_name, disableable: true, &block)
    definition_proxy = PolicyFactory.new tbl_name.to_sym

    if disableable
      definition_proxy.instance_eval do
        self.disableable
      end
    end

    definition_proxy.instance_eval(&block)
  end
end