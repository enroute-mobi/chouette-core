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
      change_scope(if: value.present?) do |scope|
        criticities = Array(value).reject(&:blank?)
        if criticities.any?
          scope.where(criticity: criticities)
        else
          scope
        end
      end
    end

    def file(value)
      change_scope(if: value.present?) do |scope|
        scope.joins(:resource).where('import_resources.name ILIKE ?', "%#{value}%")
      end
    end
  end
end
