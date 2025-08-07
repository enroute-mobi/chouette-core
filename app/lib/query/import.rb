module Query
  class Import < Query::Operation
    def tags(values)
      change_scope(if: values.present?) do |scope|
        scope.joins(:tags).where('tags.id': values).distinct
      end
    end
  end
end
