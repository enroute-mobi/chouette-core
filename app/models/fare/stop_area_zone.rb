# frozen_string_literal: true

module Fare
  # Link StopArea and Zone
  class StopAreaZone < ApplicationModel
    self.table_name = 'fare_stop_areas_zones'

    belongs_to :stop_area, class_name: 'Chouette::StopArea'
    belongs_to :zone, class_name: 'Fare::Zone', foreign_key: 'fare_zone_id'
  end
end
