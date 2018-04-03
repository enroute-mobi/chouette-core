require 'range_ext'
require_relative '../calendar/period'

module Chouette
  class PurchaseWindow < Chouette::TridentActiveRecord
    # include ChecksumSupport
    include ObjectidSupport
    include PeriodSupport
    include ChecksumSupport
    extend Enumerize

    enumerize :color, in: %w(#9B9B9B #FFA070 #C67300 #7F551B #41CCE3 #09B09C #3655D7 #6321A0 #E796C6 #DD2DAA)

    has_paper_trail
    belongs_to :referential
    has_and_belongs_to_many :vehicle_journeys, :class_name => 'Chouette::VehicleJourney'

    validates_presence_of :name, :referential

    scope :contains_date, ->(date) { where('date ? <@ any (date_ranges)', date) }
    scope :overlap_dates, ->(date_range) { where('daterange(?, ?) && any (date_ranges)', date_range.first, date_range.last + 1.day) }
    scope :matching_dates, ->(date_range) { where('ARRAY[daterange(?, ?)] = date_ranges', date_range.first, date_range.last + 1.day) }

    def self.ransackable_scopes(auth_object = nil)
      [:contains_date]
    end

    def self.colors_i18n
      Hash[*color.values.map{|c| [I18n.t("enumerize.purchase_window.color.#{c[1..-1]}"), c]}.flatten]
    end

    def local_id
      "IBOO-#{self.referential.id}-#{self.id}"
    end

    def checksum_attributes
      attrs = ['name', 'color', 'referential_id']
      ranges_attrs = date_ranges.map{|r| [r.first, r.last]}.flatten.sort
      self.slice(*attrs).values + ranges_attrs
    end

    def bounding_dates
      [
        date_ranges.map(&:first).min,
        date_ranges.map(&:last).max,
      ]
    end

    def intersect_periods! mask_periods
      return unless mask_periods.present?
      out = []
      date_ranges.each do |range|
        intersecting = mask_periods.select { |p| p.intersect? range }
        next unless intersecting.any?
        intersecting.each do |p|
          range &= p
        end
        out << range
      end
      self.update_attribute :date_ranges, out
    end
  end
end
