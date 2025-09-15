module Query
  class Import < Query::LegacyOperation
    def tags(values)
      change_scope(if: value_present?(values)) do |scope|
        scope.joins(:tags).where(::Tag.quoted_table_name => { id: values }).distinct
      end
    end
  end
end
