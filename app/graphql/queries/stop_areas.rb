# frozen_string_literal: true

module Queries
  class StopAreas < Queries::BaseQuery
    description 'Find all stop areas'

    type Types::StopAreaType.connection_type, null: false

    scope :stop_areas
  end
end
