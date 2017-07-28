require 'range_ext'
require_relative 'calendar/date_value'
require_relative 'calendar/period'

class Calendar < ActiveRecord::Base

  belongs_to :organisation
  has_many :time_tables

  validates_presence_of :name, :short_name, :organisation
  validates_uniqueness_of :short_name

  after_initialize :init_dates_and_date_ranges

  scope :contains_date, ->(date) { where('date ? = any (dates) OR date ? <@ any (date_ranges)', date, date) }

  def init_dates_and_date_ranges
    self.dates ||= []
    self.date_ranges ||= []
  end

  def self.ransackable_scopes(auth_object = nil)
    [:contains_date]
  end

  def convert_to_time_table
    Chouette::TimeTable.new.tap do |tt|
      self.dates.each do |d|
        tt.dates << Chouette::TimeTableDate.new(date: d, in_out: true)
      end
      self.periods.each do |p|
        tt.periods << Chouette::TimeTablePeriod.new(period_start: p.begin, period_end: p.end)
      end
      tt.int_day_types = 508
    end
  end


  ### Calendar::Period
  # Required by coocon
  def build_period
    Calendar::Period.new
  end

  def periods
    @periods ||= init_periods
  end

  def init_periods
    (date_ranges || [])
      .each_with_index
      .map( &Calendar::Period.method(:from_range) )
  end
  private :init_periods

  validate :validate_periods

  def validate_periods
    periods_are_valid = periods.all?(&:valid?)

    periods.each do |period|
      if period.intersect?(periods)
        period.errors.add(:base, I18n.t('calendars.errors.overlapped_periods'))
        periods_are_valid = false
      end
    end

    unless periods_are_valid
      errors.add(:periods, :invalid)
    end
  end

  def flatten_date_array attributes, key
    date_int = %w(1 2 3).map {|e| attributes["#{key}(#{e}i)"].to_i }
    Date.new(*date_int)
  end

  def periods_attributes=(attributes = {})
    @periods = []
    attributes.each do |index, period_attribute|
      # Convert date_select to date
      ['begin', 'end'].map do |attr|
        period_attribute[attr] = flatten_date_array(period_attribute, attr)
      end
      period = Calendar::Period.new(period_attribute.merge(id: index))
      @periods << period unless period.marked_for_destruction?
    end

    date_ranges_will_change!
  end

  before_validation :fill_date_ranges

  def fill_date_ranges
    if @periods
      self.date_ranges = @periods.map(&:range).compact.sort_by(&:begin)
    end
  end

  after_save :clear_periods

  def clear_periods
    @periods = nil
  end

  private :clear_periods

  ### Calendar::DateValue

  # Required by coocon
  def build_date_value
    Calendar::DateValue.new
  end

  def date_values
    @date_values ||= init_date_values
  end

  def init_date_values
    if dates
      dates.each_with_index.map { |d, index| Calendar::DateValue.from_date(index, d) }
    else
      []
    end
  end
  private :init_date_values

  validate :validate_date_values

  def validate_date_values
    date_values_are_valid = date_values.all?(&:valid?)

    date_values.each do |date_value|
      if date_values.count { |d| d.value == date_value.value } > 1
        date_value.errors.add(:base, I18n.t('activerecord.errors.models.calendar.attributes.dates.date_in_dates'))
        date_values_are_valid = false
      end
      date_ranges.each do |date_range|
        if date_range.cover? date_value.value
          date_value.errors.add(:base, I18n.t('activerecord.errors.models.calendar.attributes.dates.date_in_date_ranges'))
          date_values_are_valid = false
        end
      end
    end

    unless date_values_are_valid
      errors.add(:date_values, :invalid)
    end
  end

  def date_values_attributes=(attributes = {})
    @date_values = []
    attributes.each do |index, date_value_attribute|
      date_value_attribute['value'] = flatten_date_array(date_value_attribute, 'value')
      date_value = Calendar::DateValue.new(date_value_attribute.merge(id: index))
      @date_values << date_value unless date_value.marked_for_destruction?
    end

    dates_will_change!
  end

  before_validation :fill_dates

  def fill_dates
    if @date_values
      self.dates = @date_values.map(&:value).compact.sort
    end
  end

  after_save :clear_date_values

  def clear_date_values
    @date_values = nil
  end

  private :clear_date_values

end
