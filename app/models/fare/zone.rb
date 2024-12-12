# frozen_string_literal: true

module Fare
  # A Zone (including Stop Areas) used to define Fare validities
  class Zone < ApplicationModel
    self.table_name = :fare_zones

    belongs_to :fare_provider, class_name: 'Fare::Provider', optional: false
    has_one :fare_referential, through: :fare_provider
    has_one :workbench, through: :fare_provider

    include CodeSupport

    validates :name, presence: true

    has_many :stop_area_zones, class_name: 'Fare::StopAreaZone', foreign_key: 'fare_zone_id', dependent: :delete_all
    has_many :stop_areas, through: :stop_area_zones
    has_many :fare_geographic_references, class_name: 'Fare::GeographicReference',
                                          foreign_key: 'fare_zone_id',
                                          dependent: :delete_all
    accepts_nested_attributes_for :fare_geographic_references, allow_destroy: true, reject_if: :all_blank

    validates_associated :fare_geographic_references
    validate :validate_fare_geographic_references

    def validate_fare_geographic_references
      return if GeographicReferenceUniqueness.new(fare_geographic_references).valid?

      errors.add(:fare_geographic_references, :invalid)
    end

    class GeographicReferenceUniqueness
      def initialize(fare_geographic_references)
        @fare_geographic_references = fare_geographic_references
      end
      attr_reader :fare_geographic_references

      def valid?
        validate
      end

      def validate
        return true if duplicated_short_name.empty?

        duplicated_short_name.each do |fare_geographic_reference|
          fare_geographic_reference.errors.add(
            :short_name,
            :duplicate_values_in_fare_geographic_references
          )
        end

        false
      end

      def duplicated_short_name
        fare_geographic_references
          .group_by(&:short_name)
          .flat_map { |_, group| group.many? ? group : [] }
      end
    end
  end
end
