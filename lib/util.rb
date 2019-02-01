module RLS
  module Util
    def derive_fk tbl, rel
      obj_klass = tbl.to_s.classify.constantize
      obj_klass.reflections[rel.to_s].foreign_key
    rescue NameError
      rel + '_id'
    end

    def derive_rel_tbl rel
      rel_klass = rel.to_s.classify.constantize
      rel_klass.table_name
    rescue NameError
      rel.to_s.pluralize
    end
  end
end