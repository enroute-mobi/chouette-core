# frozen_string_literal: true

# = Period
#
# Smart Date Range
#
# == Creation
#
#   Period.new from: Time.zone.today, to: Date.parse('...')
#   Period.new from: '2030-01-01', to: '2030-12-31'
#   Period.new from: :today, to: :tomorrow
#
# Periods can be created with helper methods:
#
#   Period.from(begin) # => begin..
#   Period.from(begin).until(end) # => begin..end
#   Period.from(begin).during(1.day) # => begin..begin
#   Period.from(begin).during(10.days) # => begin..begin+9
#   Period.until(end).during(10.days) # => end-9..end
#
#   Period.from(:today) # => Time.zone.today..
#   Period.from(:yesterday) # => Time.zone.yesterday..
#   Period.from(:tomorrow) # => Time.zone.tomorrow..
#
#   Period.after(date) # => date+1..
#   Period.after(period) # => period.end+1..
#   Period.before(date) # => ..date-1
#   Period.after(period) # => ..period.begin-1
#
# == Infinite / endless
#
# Periods can be created with begin or end
#
#   Period.from(begin).infinite? # => true
#
# == Use in ActiveRecord queries
#
# To find models with a time attribute in a Period
#
#   where started_at: period.time_range
#
# To support infinite Period:
#
#   where started_at: period.infinite_time_range
#
class Period < Range
  extend ActiveModel::Naming
  include ActiveModel::Validations

  alias start_date begin
  alias from begin

  alias end_date end
  alias to end

  def initialize(from: nil, to: nil)
    from = self.class.to_date(from)
    to = self.class.to_date(to)
    super from, to
  end

  def persisted?
    false
  end

  # Use given definition to Period
  #
  # Period.parse '2030-01-01..2030-12-31'
  # Period.parse '01-01..15-06'
  # Period.parse '01..15'
  #
  # Period.parse '2030-01-01..'
  # Period.parse '..2030-12-31'
  #
  # Accepts ranges:
  #
  # Period.parse 1..15
  def self.parse(definition)
    case definition
    when String
      if /\A(.*)\.\.(.*)\z/ =~ definition
        new from: $1, to: $2
      end
    when Range
      new from: definition.begin.to_s, to: definition.end.to_s
    end
  end

  def self.for_range(range)
    RangeDecorator.new(range).period
  end

  # Period.from(Date.yesterday)
  def self.from(from)
    new from: from
  end

  # Period.until(Date.yesterday)
  # Period.from(Date.yesterday).until(Date.tomorrow)
  def self.until(to)
    new to: to
  end

  # Period.after(date) returns a Period from the day after the given date
  # Period.after(period]) returns a Period from the day after the last day of the given period
  def self.after(date_or_period)
    date =
      if date_or_period.respond_to?(:end)
        date_or_period.end
      else
        date_or_period
      end

    from date+1
  end

  # Period.before(date) returns a Period until the day before the given date
  # Period.before(period) returns a Period util the day before the first day of the given period
  def self.before(date_or_period)
    date =
      if date_or_period.respond_to?(:begin)
        date_or_period.begin
      else
        date_or_period
      end

    self.until date-1
  end

  def until(to)
    self.class.new from: from, to: to
  end

  # Returns the Time at the middle of the Period
  def mid_time
    return nil if infinite?
    from.to_time + duration / 2.0
  end
  alias middle mid_time

  # period.during(14.days)
  # period.during(1.month)
  # Period.from(Date.today).during(14.days)
  # Period.until(Date.today).during(14.days)
  def during(duration)
    in_days = duration.respond_to?(:in_days) ? duration.in_days : duration / 1.day

    delta = in_days - 1
    return self if delta < 0

    if from
      self.class.new from: from, to: from + delta
    elsif to
      self.class.new from: to - delta, to: to
    else
      self
    end
  end

  # Period.during(14.days)
  # Period.from(Date.yesterday).during(1.month)
  def self.during(duration)
    from(Time.zone.today).during(duration)
  end

  def valid?
    validate!
    errors.empty?
  end

  def validate!
    unless from || to
      errors.add(:from, :invalid_bounds)
      errors.add(:to, :invalid_bounds)
    end

    if (from && to) && (to < from)
      errors.add(:from, :to_before_from)
      errors.add(:to, :to_before_from)
    end
    errors
  end

  def empty?
    from.nil? && to.nil?
  end

  def infinite?
    from.nil? || to.nil?
  end
  alias endless? infinite?

  # Redefine #size method to compute dates
  def size
    if infinite?
      Float::INFINITY
    else
      if from <= to
        (to - from).to_i + 1
      else
        0
      end
    end
  end
  alias day_count size

  def duration
    return nil if infinite?
    day_count.days
  end

  def infinity_date_range
    range_begin = from ? from&.to_date : -Float::INFINITY
    range_end = to ? to&.to_date : Float::INFINITY

    range_begin..range_end
  end

  def time_range
    range_begin = from&.to_datetime
    range_end = to ? (to + 1).to_datetime : nil

    range_begin..range_end
  end

  def infinite_time_range
    range = time_range

    range_begin = range.begin || -Float::INFINITY
    range_end = range.end || Float::INFINITY

    Range.new range_begin, range_end
  end

  def include?(date)
    date = self.class.to_date(date)

    if from && to
      super date
    elsif from
      from <= date
    elsif to
      date <= to
    else
      true
    end
  end

  # Returns the date if included in the Period
  # Returns Period from if the date is before Period
  # Returns Period to if the date is after Period
  def limit(date)
    [
      [ date, from ].compact.max,
      to
    ].compact.min
  end

  # Internal - Invokes to_date method if available
  # Invokes to_date method if available
  #
  # Special cases:
  #
  # * transforms a Symbol into Time.zone method invocation
  # * prefix a String with a single number with '0' to make it valid
  #
  def self.to_date(date)
    date = Time.zone.send(date) if date.is_a? Symbol

    # Transforms '1' into '01'. Because single number is an invalid date
    date = "0#{date}" if date.is_a?(String) && /\A[0-9]\z/ =~ date

    date = date.to_date if date.respond_to?(:to_date)

    date
  end

  # Internal - Use Period.for_range
  # Create a Period from a Range
  class RangeDecorator
    def initialize(range)
      @range = range
    end
    attr_reader :range

    def period
      Period.new(from: from, to: to) if from || to
    end

    def from
      @from ||= range.begin unless beginless?
    end

    def to
      @to ||= range.end.to_date - end_correction unless endless?
    end

    def beginless?
      range.begin.nil? || range.begin == -Float::INFINITY
    end

    def endless?
      range.end.nil? || range.end == Float::INFINITY
    end

    def end_correction
      range.exclude_end? ? 1 : 0
    end
  end

  # Uses with ActiveRecord attribute method to store a Period
  #
  #   attribute :validity_period, Period::Type.new
  #
  class Type < ActiveRecord::Type::Value
    def cast(value)
      return nil unless value.present?

      case value
      when String
        Period.for_range oid_range.cast_value(value)
      when Hash
        Period.new from: value[:from], to: value[:to]
      when Range
        Period.for_range value
      when Period
        value
      else
        Rails.logger.debug "Could not cast Period from a #{value.class} object"
        Period.new
      end
    end

    def serialize(value)
      if value.is_a?(Period)
        return nil if value.empty?

        date_range = value.infinity_date_range
        oid_range.serialize(date_range)
      else
        value
      end
    end

    def oid_range
      self.class.oid_range
    end

    def self.oid_range
      @oid_range ||=
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Range.new(
          ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Date.new
        )
    end
  end
end
