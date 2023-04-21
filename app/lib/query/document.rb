# frozen_string_literal: true

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

    def document_provider_id(value)
      where(value, :eq, :document_provider_id)
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.where('validity_period && ? OR validity_period IS NULL', period.to_postgresql_daterange)
      end
    end
  end
end
