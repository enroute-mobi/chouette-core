module Query
  class Import < Query::Operation
    def tags(values)
      change_scope(if: values.present?) do |scope|
        scope.joins(:tags).where(::Tag.quoted_table_name => { id: values }).distinct
      end
    end
  end
end
