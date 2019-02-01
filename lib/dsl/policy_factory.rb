module DSL
  class PolicyFactory
    def initialize tbl_name
      @tbl_name = tbl_name.to_sym
    end

    def policy(policy_name, &block)
      policy = Policy.new @tbl_name, policy_name.to_sym
      policy.instance_eval(&block)
      RLS.policies[@tbl_name] ||= {}
      RLS.policies[@tbl_name][policy_name.to_sym] = policy
    end

    def disableable
      policy :all_when_disabled_rls do
        using <<-SQL
    rls_disabled()
        SQL
      end
    end

    def using_client
      policy :match_client do
        using <<-SQL
    current_client_id() = client_id
        SQL
      end
    end

    def using_relation rel
      policy ('via_'+rel.to_s.pluralize).to_sym do
        using_relation rel.to_sym
      end
    end

    def using_relations *rels
      # Unwrap arguments given in a style like 'using_relation opener: club_record_id, client: client_id'
      if rels.size == 1 && rels[0].is_a?(Hash)
        rels = rels[0]
      end

      rel_names = rels.map do |rel|
        rel = rel[1]
        if rel.respond_to? :table_name
          rel.table_name
        else
          rel.to_s.pluralize
        end
      end

      policy ('via_' + rel_names.join('_and_')).to_sym do
        using_relation *rels
      end
    end
  end
end