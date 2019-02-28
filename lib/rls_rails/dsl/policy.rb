module RLS
  class Policy
    include RLS::Util

    def initialize table, name
      @tbl = table
      @policy = name
      @permissive = true
      @to = [:public]
      @on = :all
      @using = false
      @check = false
    end

    def on(on)
      @on = on.to_sym
      raise "'#{on}' is no valid option!" unless [:all, :select, :insert, :update, :delete].include? @on
    end

    def using(using_str)
      @using = using_str
    end

    # Shorthand for creating a policy which simply checks whether the given relations are all accessible
    def using_relation *rels
      # Unwrap arguments given in a style like 'using_relation opener: :club_record_id, tenant: :tenant_id'
      rels = rels[0] if rels.size == 1 && rels[0].is_a?(Hash)

      @using = rels.map do |v|
        if v.is_a?(Array)
          fk = derive_fk @tbl, v[0]
          rel = v[1]
        else
          rel = v
          fk = derive_fk @tbl, v
        end

        rel_tbl = derive_rel_tbl(rel)
        <<-SQL
        EXISTS (
          SELECT NULL
          FROM #{rel_tbl}
          WHERE #{rel_tbl}.id = #{@tbl}.#{fk}
        )
        SQL
      end.join("      AND\n")
    end

    def check(check_str)
      @check = check_str
    end

    def permissive
      @permissive = true
    end

    def restrictive
      @permissive = false
    end

    def permissive?
      @permissive
    end

    def restrictive?
      !permissive?
    end

    def to *name
      @to = Array.wrap(name).map(&:to_sym)
    end

    def to_create_sql
      tos = @to.map(&:to_s).join(', ').upcase
      q =  "CREATE POLICY #{@policy} ON #{@tbl}\n"
      q << "AS #{@permissive ? 'PERMISSIVE' : 'RESTRICTIVE'}\n" unless @permissive
      q << "FOR #{@on}\n"
      q << "TO #{tos}\n" if tos != 'PUBLIC'
      q << "USING (\n#{@using})" if @using.present?
      q << "WITH CHECK (\n#{@check})" if @check.present?
      q << ';'
    end

    def to_drop_sql
      "DROP POLICY IF EXISTS #{@policy} ON #{@tbl};"
    end

    def tenant_fk
      Railtie.config.rls_rails.tenant_fk
    end
  end
end