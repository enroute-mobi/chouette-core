# frozen_string_literal: true

module Queries
  class StopArea < Queries::BaseQuery
    include ByObjectidOrRegistrationNumber
    include ByCode

    description 'Find a stop area'

    type Types::StopAreaType, null: true

    scope :stop_areas

    def resolve(**kwargs)
      super.take
    end
  end
end
