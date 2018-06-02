require 'range_ext'
require_relative '../calendar/period'

module Chouette
  class PurchaseWindow < Chouette::TridentActiveRecord
    include ObjectidSupport
    include PeriodSupport
    include ChecksumSupport
    include ColorSupport

    has_metadata
    belongs_to :referential
    has_and_belongs_to_many :vehicle_journeys, :class_name => 'Chouette::VehicleJourney'

    validates_presence_of :name, :referential

    scope :contains_date, ->(date) { where('date ? <@ any (date_ranges)', date) }
    scope :overlap_dates, ->(date_range) { where('daterange(?, ?) && any (date_ranges)', date_range.first, date_range.last + 1.day) }
    scope :matching_dates, ->(date_range) { where('ARRAY[daterange(?, ?)] = date_ranges', date_range.first, date_range.last + 1.day) }

    # VehicleJourneys include PurchaseWindow checksums in their checksums
    # OPTIMIZEME
    def update_vehicle_journey_checksums
      vehicle_journeys.find_each(&:update_checksum!)
    end
    after_commit :update_vehicle_journey_checksums

    def self.ransackable_scopes(auth_object = nil)
      [:contains_date]
    end

    def local_id
      "IBOO-#{self.referential.id}-#{self.id}"
    end

    def checksum_attributes
      attrs = ['name', 'color', 'referential_id']
      ranges_attrs = date_ranges.map{|r| [r.min, r.max]}.flatten.sort
      self.slice(*attrs).values + ranges_attrs
    end

    def bounding_dates
      [
        date_ranges.map(&:first).min,
        date_ranges.map(&:max).max,
      ]
    end
  end
end
