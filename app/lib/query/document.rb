module Query
  class Document < Base
    def name(value)
      where(value, :matches, :name)
    end

    def document_type(document_type)
      change_scope(if: document_type.present?) do |scope|
        scope.with_type(document_type)
      end
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.where('period::daterange && daterange(:begin, :end)', begin: period.min, end: (period.max + 1.day)) # Need to add one day because of PostgreSQL behaviour with daterange (exclusvive end)
      end
    end

  end
end