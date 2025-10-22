# frozen_string_literal: true

module Queries
  class Line < Queries::BaseQuery
    include ByObjectidOrRegistrationNumber
    include ByCode

    description 'Find a line'

    type Types::LineType, null: true

    scope :lines

    def resolve(**kwargs)
      super.take
    end
  end
end
