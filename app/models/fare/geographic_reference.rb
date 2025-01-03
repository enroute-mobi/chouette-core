# frozen_string_literal: true

module Fare
  class GeographicReference < ApplicationModel
    self.table_name = 'fare_geographic_references'

    belongs_to :fare_zone, class_name: 'Fare::Zone', foreign_key: 'fare_zone_id' # TODO CHOUETTE-3247 required: true

    validates :short_name, presence: true, uniqueness: { scope: :fare_zone_id }
  end
end
