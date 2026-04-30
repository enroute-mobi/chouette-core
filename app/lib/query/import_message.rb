# frozen_string_literal: true

module Query
  class ImportMessage < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        message_key = table[:message_key].matches("%#{value}%")
        source = Arel.sql("message_attributes::text ILIKE '%#{value}%'")

        scope.where(message_key.or(source))
      end
    end

    def criticity(value)
      criticities = Array(value).reject(&:blank?)
      change_scope(if: criticities.any?) do |scope|
        scope.where(criticity: criticities)
      end
    end

    def file(value)
      change_scope(if: value.present?) do |scope|
        scope.where("resource_attributes->'filename' ILIKE ?", "%#{value}%")
      end
    end
  end
end
