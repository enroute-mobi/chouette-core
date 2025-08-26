# frozen_string_literal: true

module Query
  class Publication < Query::Operation
    def publication_setup_id(value)
      change_scope(if: value_present?(value)) do |scope|
        scope.where(publication_setup_id: value)
      end
    end
  end
end
