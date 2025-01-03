# frozen_string_literal: true

module Fare
  # A Zone (including Stop Areas) used to define Fare validities
  class Zone < ApplicationModel
    self.table_name = :fare_zones

    belongs_to :fare_provider, class_name: 'Fare::Provider' # CHOUETTE-3247 optional: false
    has_one :fare_referential, through: :fare_provider
    has_one :workbench, through: :fare_provider

    include CodeSupport

    validates :name, presence: true

    has_many :stop_area_zones, class_name: 'Fare::StopAreaZone', foreign_key: 'fare_zone_id', dependent: :delete_all
    has_many :stop_areas, through: :stop_area_zones
    has_many :fare_geographic_references, class_name: 'Fare::GeographicReference',
                                          foreign_key: 'fare_zone_id',
                                          dependent: :delete_all,
                                          inverse_of: 'fare_zone'

    accepts_nested_attributes_for :fare_geographic_references, allow_destroy: true, reject_if: :all_blank

    validates_associated :fare_geographic_references
  end
end
