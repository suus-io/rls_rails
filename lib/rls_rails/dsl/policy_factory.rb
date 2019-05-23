module RLS
  class PolicyFactory
    include RLS::Util

    def initialize tbl_name
      @tbl_name = tbl_name.to_sym
    end

    def policy(policy_name, &block)
      policy = Policy.new @tbl_name, policy_name.to_sym
      policy.instance_eval(&block)
      RLS.policies[@tbl_name] ||= {}
      RLS.policies[@tbl_name][policy_name.to_sym] = policy
    end

    def disableable &block
      p = policy :all_when_disabled_rls do
        using <<-SQL
    rls_disabled()
        SQL
      end
      p.instance_eval(&block) if block_given?
      p
    end

    def using_tenant &block
      p = policy :match_tenant do
        using <<-SQL
    current_tenant_id() = #{tenant_fk}
        SQL
      end
      p.instance_eval(&block) if block_given?
      p
    end

    def check_tenant &block
      p = policy :check_tenant do
        check <<-SQL
    current_tenant_id() = #{tenant_fk}
        SQL
      end
      p.instance_eval(&block) if block_given?
      p
    end

    def using_relation rel, &block
      p = policy(('via_'+ rel.to_s.pluralize).to_sym) do
        using_relation rel.to_sym
      end
      p.instance_eval(&block) if block_given?
      p
    end

    def using_relations(*rels)
      # Unwrap arguments given in a style like 'using_relation opener: :club_record_id, tenant: :tenant_id'
      if rels.size == 1 && rels[0].is_a?(Hash)
        rels = rels[0]
        rel_names = rels.map(&:second).map(&method(:derive_rel_tbl)).map(&:to_s)
      else
        rel_names = rels.map(&method(:derive_rel_tbl)).map(&:to_s)
      end

      policy(('via_' + rel_names.join('_and_')).to_sym) do
        using_relation(*rels)
      end
    end

    # Shorthand to create a policy that admits rows that find a join partner in another table
    def using_table(other_tbl, match: nil, primary_key: match, foreign_key: match, tenant_id: tenant_fk, &block)
      other_tbl = derive_rel_tbl other_tbl
      p = policy("match_#{other_tbl}_on_#{primary_key}_eq_#{foreign_key}".to_sym) do
        using <<-SQL
    EXISTS (
      SELECT NULL
      FROM #{other_tbl}
      WHERE #{@tbl}.#{primary_key} = #{other_tbl}.#{foreign_key}
        AND #{other_tbl}.#{tenant_id} = current_tenant_id()
    )
        SQL
      end
      p.instance_eval(&block) if block_given?
      p
    end

    # Shorthand to create a policy that admits rows that find a join partner in another table
    def check_table(other_tbl, match: nil, primary_key: match, foreign_key: match, tenant_id: tenant_fk)
      other_tbl = derive_rel_tbl other_tbl
      policy("check_#{other_tbl}_on_#{primary_key}_eq_#{foreign_key}".to_sym) do
        check <<-SQL
    EXISTS (
      SELECT NULL
      FROM #{other_tbl}
      WHERE #{@tbl}.#{primary_key} = #{other_tbl}.#{foreign_key}
        AND #{other_tbl}.#{tenant_id} = current_tenant_id()
    )
        SQL
      end
    end

    def tenant_fk
      Railtie.config.rls_rails.tenant_fk
    end
  end
end