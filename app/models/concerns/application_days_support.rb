module ApplicationDaysSupport
  extend ActiveSupport::Concern

  NONE = 0

  MONDAY    = 4
  TUESDAY   = 8
  WEDNESDAY = 16
  THURSDAY  = 32
  FRIDAY    = 64
  SATURDAY  = 128
  SUNDAY    = 256
  EVERYDAY  = MONDAY | TUESDAY | WEDNESDAY | THURSDAY | FRIDAY | SATURDAY | SUNDAY

  ALL_DAYS = %w(monday tuesday wednesday thursday friday saturday sunday).freeze
  RUBY_WEEKDAYS = [SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY].freeze

  def display_day_types
    ALL_DAYS.select{ |d| self.send(d) }.map{ |d| self.human_attribute_name(d).first(2)}.join(', ')
  end

  def day_by_mask(flag)
    self.class.day_by_mask int_day_types, flag
  end

  def applicable_date?(date)
    applicable_weekday? date.wday if date
  end

  # Returns if the day of week (0-6, Sunday is zero) is selected
  def applicable_weekday?(weekday)
    return false unless weekday >= 0 and weekday < RUBY_WEEKDAYS.size
    day_by_mask(RUBY_WEEKDAYS[weekday])
  end

  def valid_day? wday
    wday = wday.wday if wday.respond_to?(:wday)
    wday = wday % 7
    wday = 7 if wday == 0 # 0-6 -> 1-7
    valid_days.include?(wday)
  end

  included do
    def self.valid_days(int_day_types)
      # Build an array with day of calendar week (1-7, Monday is 1).
      [].tap do |valid_days|
        valid_days << 1  if day_by_mask(int_day_types,MONDAY)
        valid_days << 2  if day_by_mask(int_day_types,TUESDAY)
        valid_days << 3  if day_by_mask(int_day_types,WEDNESDAY)
        valid_days << 4  if day_by_mask(int_day_types,THURSDAY)
        valid_days << 5  if day_by_mask(int_day_types,FRIDAY)
        valid_days << 6  if day_by_mask(int_day_types,SATURDAY)
        valid_days << 7  if day_by_mask(int_day_types,SUNDAY)
      end
    end

    def self.day_by_mask(int_day_types,flag)
      int_day_types & flag == flag
    end

    def self.all_days
      ALL_DAYS
    end
  end

  def valid_days
    self.class.valid_days int_day_types
  end

  def monday
    day_by_mask(MONDAY)
  end
  def tuesday
    day_by_mask(TUESDAY)
  end
  def wednesday
    day_by_mask(WEDNESDAY)
  end
  def thursday
    day_by_mask(THURSDAY)
  end
  def friday
    day_by_mask(FRIDAY)
  end
  def saturday
    day_by_mask(SATURDAY)
  end
  def sunday
    day_by_mask(SUNDAY)
  end

  def set_day(day,flag)
    if day == '1' || day == true
      self.int_day_types |= flag
    else
      self.int_day_types &= ~flag
    end
    shortcuts_update
  end

  def monday=(day)
    set_day(day,4)
  end
  def tuesday=(day)
    set_day(day,8)
  end
  def wednesday=(day)
    set_day(day,16)
  end
  def thursday=(day)
    set_day(day,32)
  end
  def friday=(day)
    set_day(day,64)
  end
  def saturday=(day)
    set_day(day,128)
  end
  def sunday=(day)
    set_day(day,256)
  end

  def days_of_week
    Cuckoo::Timetable::DaysOfWeek.from_int_day_types(int_day_types)
  end

  def days_of_week=(days_of_week)
    self.int_day_types = days_of_week.chouette_days_mask
  end

end
