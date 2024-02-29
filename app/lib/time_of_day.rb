# Manage time of day like 22:00 without date concept but with support for:
# * utc_offset / time_zone
# * day_offset
#
# Can be created from a Time:
#
# TimeOfDay.create(Time.zone.parse("2021-07-15 21:59:25 +0200")).to_s
# => "08:48:25 utc_offset:3600"
#
# Can be created from a string:
#
# TimeOfDay.parse("22:00").to_s
# => "22:00:00"
# TimeOfDay.parse("22:00", time_zone: Time.zone).to_s
# => "22:00:00 utc_offset:3600"
#
# Can be created from the current time:
#
# TimeOfDay.now.to_s
# => "10:02:44 utc_offset:3600"
# TimeOfDay.now(time_zone: Time.find_zone('Eastern Time (US & Canada)')).to_s
# => "04:02:47 utc_offset:-18000"

class TimeOfDay
  include Comparable

  attr_reader :hour, :minute, :second, :day_offset, :utc_offset, :second_offset
  alias min minute
  alias sec second

  def initialize(hour, minute = nil, second = nil, day_offset: nil, utc_offset: nil, time_zone: nil)
    utc_offset = time_zone.utc_offset if time_zone

    @hour = hour.to_i
    @minute = minute.to_i
    @second = second.to_i
    @day_offset = day_offset.to_i
    @utc_offset = utc_offset.to_i

    @second_offset = ((@day_offset * 24 + @hour) * 60 + @minute) * 60 + @second - @utc_offset
  end

  def self.create(time = nil, attributes = nil)
    attributes ||= {}

    %i[hour minute min second sec day_offset time_zone].each do |attribute|
      attributes[attribute] = time.send(attribute) if time.respond_to?(attribute)
    end

    if minute = attributes.delete(:min)
      attributes[:minute] = minute
    end
    if second = attributes.delete(:sec)
      attributes[:second] = second
    end

    new attributes.fetch(:hour), attributes[:minute], attributes[:second], attributes.except(:hour, :minute, :second)
  end

  def self.now(time_zone: Time.zone)
    create time_zone.now
  end

  ONE_DAY = 1.day.to_i
  ONE_HOUR = 1.hour.to_i
  ONE_MINUTE = 1.minute.to_i

  def self.from_second_offset(offset, utc_offset: 0)
    offset += utc_offset

    day_offset = offset / ONE_DAY
    offset = offset % ONE_DAY

    hour = offset / ONE_HOUR
    offset = offset % ONE_HOUR

    minute = offset / ONE_MINUTE
    second = offset % ONE_MINUTE

    TimeOfDay.new hour, minute, second, day_offset: day_offset, utc_offset: utc_offset
  end

  def without_utc_offset
    self.class.from_second_offset second_offset
  end

  def add(seconds: 0, day_offset: 0)
    self.class.from_second_offset second_offset + seconds + day_offset.days, utc_offset: utc_offset
  end

  def with_utc_offset(utc_offset)
    self.class.from_second_offset second_offset, utc_offset: utc_offset
  end

  mattr_reader :zones_utc_offset, default: {}

  def self.zone_utc_offset(time_zone)
    zones_utc_offset[time_zone.to_s] ||=
      begin
        time_zone = ActiveSupport::TimeZone[time_zone] if time_zone.is_a?(String)
        time_zone&.utc_offset || 0
      end
  end

  def with_zone(time_zone)
    with_utc_offset(self.class.zone_utc_offset(time_zone))
  end

  # Returns the *same* hour/minute into another TimeZone
  #
  # TimeOfDay.new(6).force_zone("Europe/Paris").to_s
  # => "06:00:00 utc_offset:3600"
  def force_zone(time_zone)
    time_zone = ActiveSupport::TimeZone[time_zone] if time_zone.is_a?(String)
    utc_offset = time_zone&.utc_offset || 0
    self.class.from_second_offset second_offset - utc_offset, utc_offset: utc_offset
  end

  def with_day_offset(offset)
    self.class.from_second_offset second_offset + (offset - day_offset).days, utc_offset: utc_offset
  end

  def day_offset?
    day_offset != 0
  end

  def utc_offset?
    utc_offset != 0
  end

  HMS_FORMAT = '%.2d:%.2d:%.2d'
  def to_hms
    format(HMS_FORMAT, hour, minute, second)
  end

  HM_FORMAT = '%.2d:%.2d'
  def to_hm
    format(HM_FORMAT, hour, minute)
  end

  def to_s
    [].tap do |parts|
      parts << to_hms
      parts << "day:#{day_offset}" if day_offset?
      parts << "utc_offset:#{utc_offset}" if utc_offset?
    end.join(' ')
  end

  def to_vehicle_journey_at_stop_time
    ::Time.new(2000, 1, 1, hour, minute, second, '+00:00')
  end

  alias to_time to_vehicle_journey_at_stop_time

  def to_iso_8601
    @iso_8601 ||= ISO8601.new(self).to_s
  end

  def -(other)
    second_offset - other.second_offset
  end

  def ==(other)
    second_offset == other.second_offset
  end
  alias eql? ==

  def hash
    second_offset
  end

  INPUT_HASH_HOUR = 1
  INPUT_HASH_MINUTE = 2
  INPUT_HASH_SECOND = 3
  INPUT_HASH_DAY_OFFSET = 4
  def self.from_input_hash(hash)
    TimeOfDay.new(hash[INPUT_HASH_HOUR], hash[INPUT_HASH_MINUTE], hash.fetch(INPUT_HASH_SECOND, 0),
                  day_offset: hash[INPUT_HASH_DAY_OFFSET])
  end

  class ISO8601 < SimpleDelegator
    UTC_FORMAT = '%.2d:%.2d:%.2dZ'.freeze
    NON_UTC_FORMAT = '%.2d:%.2d:%.2d%s%.2d:%.2d'.freeze

    def to_s
      if utc_offset?
        format(NON_UTC_FORMAT, hour, minute, second, sign_utc_offset, hour_utc_offset, minute_utc_offset)
      else
        format(UTC_FORMAT, hour, minute, second)
      end
    end

    def sign_utc_offset
      utc_offset >= 0 ? '+' : '-'
    end

    def hour_utc_offset
      utc_offset.abs / 1.hour
    end

    def minute_utc_offset
      utc_offset.abs % 1.hour / 1.minute
    end
  end

  def <=>(other)
    return unless other.respond_to?(:second_offset)

    @second_offset <=> other.second_offset
  end

  PARSE_REGEX = /
      \A
      ([01]?\d|2[0-4])
      :?
      ([0-5]\d)?
      :?
      ([0-5]\d)?
      \z
    /x

  def self.parse(definition, attributes = nil)
    return unless PARSE_REGEX =~ definition

    hour = ::Regexp.last_match(1)
    minute = ::Regexp.last_match(2)
    second = ::Regexp.last_match(3)
    new hour, minute, second, attributes || {}
  end

  def self.unserialize(value, attributes = nil)
    return nil if value.nil?

    if value.is_a?(String)
      parse value, attributes
    else
      create value, attributes
    end
  end

  module Type
    class TimeWithoutZone < ActiveRecord::Type::Value
      def cast(value)
        return unless value.present?
        return TimeOfDay.parse(value).force_zone(Time.zone) if value.is_a?(String)

        value
      end

      def serialize(value)
        return unless value.present?

        value.to_hms
      end

      def changed_in_place?(raw_old_value, new_value)
        raw_old_value != serialize(new_value)
      end
    end

    class SecondOffset < ActiveRecord::Type::Value
      def cast(value)
        return unless value.present?

        TimeOfDay.from_second_offset(value)
      end

      def serialize(value)
        return unless value.present?

        value.second_offset
      end

      def changed_in_place?(raw_old_value, new_value)
        raw_old_value != serialize(new_value)
      end
    end
  end
end
