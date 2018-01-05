require 'activeattr_ext.rb'
require 'range_ext'

class ReferentialMetadata < ActiveRecord::Base
  belongs_to :referential, touch: true
  belongs_to :referential_source, class_name: 'Referential'
  has_array_of :lines, class_name: 'Chouette::Line'

  validates :referential, presence: true
  validates :lines, presence: true
  validates :periodes, presence: true

  scope :include_lines, -> (line_ids) { where('line_ids && ARRAY[?]::bigint[]', line_ids) }
  scope :include_dateranges, -> (dateranges) { where('periodes && ARRAY[?]', dateranges) }

  after_save do
    referential.did_update_metadatas
  end

# Transform Wed, 22 Feb 2017...Fri, 24 Feb 2017 into Wed, 22 Feb 2017..Thu, 23 Feb 2017
  def periodes
    attributes["periodes"].tap do | periods |
      return periods unless periods
      return adapted_periods(periods)
    end
  end

  def adapted_periods(periods)
    periods.map do | period |
      if period.try(:exclude_end?)
        period.begin .. (period.end - 1)
      else
        period
      end
    end
  end
  private :adapted_periods

  class Period
    include ActiveAttr::Model
    include ActiveAttr::MultiParameterAttributes

    attribute :id, type: Integer
    attribute :begin, type: Date
    attribute :end, type: Date

    validates :begin, :end, presence: true
    validate :check_end_greather_than_begin

    def check_end_greather_than_begin
      if self.begin and self.end and self.begin >= self.end
        errors.add(:base, I18n.t('referentials.errors.short_period'))
      end
    end

    def self.from_range(index, range)
      Period.new id: index, begin: range.begin, end: range.end
    end

    def range
      if self.begin and self.end and self.begin <= self.end
        Range.new self.begin, self.end
      end
    end

    def intersect?(*other)
      return false if range.nil?

      other = other.flatten
      other = other.delete_if { |o| o.id == id } if id

      other.any? do |period|
        if other_range = period.range
          (range & other_range).present?
        end
      end
    end

    # Stuff required for coocon
    def new_record?
      !persisted?
    end
    def persisted?
      id.present?
    end


    def mark_for_destruction
      self._destroy = true
    end

    attribute :_destroy, type: Boolean
    alias_method :marked_for_destruction?, :_destroy
  end

  # Required by coocon
  def build_period
    Period.new
  end

  def periods
    @periods ||= init_periods
  end

  def init_periods
    if periodes
      periodes.each_with_index.map { |r, index| Period.from_range(index, r) }
    else
      []
    end
  end
  private :init_periods

  validate :validate_periods

  def validate_periods
    periods_are_valid = true

    unless periods.all?(&:valid?)
      periods_are_valid = false
    end

    periods.each do |period|
      if period.intersect?(periods)
        period.errors.add(:base, I18n.t("referentials.errors.overlapped_period"))
        periods_are_valid = false
      end
    end

    unless periods_are_valid
      errors.add(:periods, :invalid)
    end
  end

  def periods_attributes=(attributes = {})
    @periods = []
    attributes.each do |index, period_attribute|
      period = Period.new(period_attribute.merge(id: index))
      @periods << period unless period.marked_for_destruction?
    end

    # if self.periodes != @periods.map(&:range).compact
      periodes_will_change!
    # end
  end

  before_validation :fill_periodes

  def fill_periodes
    if @periods
      self.periodes = @periods.map(&:range).compact.sort_by(&:begin)
    end
  end

  after_save :clear_periods

  def clear_periods
    @periods = nil
  end
  private :clear_periods

  def self.new_from(from, functional_scope)
    from.dup.tap do |metadata|
      metadata.referential_source_id = from.referential_id
      metadata.line_ids = from.referential.lines.where(id: metadata.line_ids, objectid: functional_scope).collect(&:id)
      metadata.referential_id = nil
    end
  end
end
