class Timetable

  def self.from(date_range)
    Timetable.new periods: [ Period.from(date_range) ]
  end

  def initialize(attributes = {})
    periods.merge Array(attributes[:periods])
    included_dates.merge Array(attributes[:included_dates])
    excluded_dates.merge Array(attributes[:excluded_dates])
  end

  def included_dates
    @included_dates ||= SortedSet.new
  end

  def excluded_dates
    @excluded_dates ||= SortedSet.new
  end

  def periods
    @periods ||= SortedSet.new
  end

  def merge(other)
    dup.merge! other
  end

  def empty?
    included_dates.empty? && excluded_dates.empty? && periods.empty?
  end

  def merge!(other)
    included_dates.merge other.included_dates
    excluded_dates.merge other.excluded_dates
    # We don't want to use the same period instances
    periods.merge other.periods.map(&:dup)

    self
  end

  # Returns a new Timetable which only keeps dates
  # and periods in the given date ranges
  def limit(*date_ranges)
    date_ranges.flatten!

    Timetable.new.tap do |limited|
      date_ranges.each do |date_range|
        limited.merge! dup.limit!(date_range)
      end
    end
  end

  # Remove dates and remove/truncate periods
  # which are not in the given *single* date range
  def limit!(date_range)
    raise "Only accept a single Date Range" unless date_range.is_a?(Range)

    included_dates.delete_if { |date| !date_range.include?(date) }
    excluded_dates.delete_if { |date| !date_range.include?(date) }

    periods.delete_if do |period|
      !period.date_range.intersect?(date_range)
    end

    periods.each do |period|
      unless date_range.include?(period.first)
        period.first = date_range.min
      end
      unless date_range.include?(period.last)
        period.last = date_range.max
      end
    end

    self
  end

  # This normalize operation is specific to Chouette.
  # TODO Create a Timetable::Optimizer::Chouette instead a normalize! method.
  # We'll need a Timetable::Optimizer::GTFS, Timetable::Optimizer::Netex, etc
  def normalize!
    # TODO move these different logics into a dedicated objects ?

    # Disabled to avoid expected changes in Chouette::TimeTable
    # Merge continuous periods
    # previous_period = nil
    # periods.delete_if do |period|
    #   if previous_period && previous_period.merge!(period)
    #     true
    #   else
    #     previous_period = period
    #     false
    #   end
    # end

    # Delete empty periods
    # Transform single day period in a included date
    periods.delete_if do |period|
      period_day_count = period.day_count

      if period_day_count > 1
        false
      else
        if period_day_count == 1
          included_dates << period.first
        end

        true
      end
    end

    self
  end

  def initialize_copy(clone)
    clone.periods = SortedSet.new(periods.map(&:dup))
  end

  def shift(days)
    raise ArgumentError.new("Timetable shift can't be negative") if days < 0

    included_dates.map! { |date| date+days }
    excluded_dates.map! { |date| date+days }

    Period.shift periods, days
  end

  attr_writer :periods
  protected :periods=

  # TODO the return value can't be in excluded_dates
  def first
    min_period = periods.min_by { |period| period.first }.first
    min_included_date = included_dates.min

    [min_period, min_included_date].compact.min
  end

  # TODO the return value can't be in excluded_dates
  def last
    max_period = periods.max_by { |period| period.first }.last
    max_included_date = included_dates.max

    [max_period, max_included_date].compact.max
  end

  # Returns the DaysOfWeeks shared by all Periods .. or nil
  # Returns DaysOfWeek.none if no period is defined
  def uniq_days_of_week
    return DaysOfWeek.none if periods.empty?

    first_days_of_week = periods&.first&.days_of_week
    if periods.all? { |p| p.days_of_week == first_days_of_week }
      first_days_of_week
    end
  end

  class Period
    include Comparable

    attr_reader :first, :last
    attr_accessor :days_of_week

    def initialize(first, last, days_of_week = DaysOfWeek.all)
      check_first_last!(first, last)

      @first, @last, @days_of_week = first, last, days_of_week
    end

    def first=(first)
      check_first_last!(first, last)
      @first = first
    end

    def last=(last)
      check_first_last!(first, last)
      @last = last
    end

    def self.from(date_range, days_of_week = DaysOfWeek.all)
      new date_range.min, date_range.max, days_of_week
    end

    def self.shift periods, days
      periods.map! do |period|
          period.first += days
          period.last += days
          period.days_of_week.shift days
          period
      end
    end

    # Returns the date range between first and last dates
    def date_range
      Range.new first, last
    end

    # Returns the number of days between first and last dates
    # ignoring the selected days of week
    def length
      (last - first).to_i + 1
    end

    def continuous?(other)
      return false unless other
      intersects?(other) || last.next == other.first || other.last.next == first
    end

    def intersects?(other)
      other && last >= other.first && other.last >= self.first
    end

    def merge!(other)
      return nil unless other
      return nil if days_of_week != other.days_of_week
      return nil unless continuous?(other)

      self.first = [first, other.first].min
      self.last = [last, other.last].max

      self
    end

    # Returns the number of days between first and last dates
    # *selected* by the days of week
    def day_count
      return length unless days_of_week

      if length == 1
        return days_of_week.match_date?(first) ? 1 : 0
      end

      # TODO
      return length
    end

    def eql?(other)
      return false unless other
      first == other.first && last == other.last && days_of_week == other.days_of_week
    end
    alias == eql?

    def hash
      [first, last, days_of_week].hash
    end

    def <=>(other)
      return nil unless other
      (first <=> other.first).nonzero? ||
        (last <=> other.last).nonzero? ||
        days_of_week <=> other.days_of_week
    end

    def to_s
      # TODO display days_of_week
      "#{first}..#{last}"
    end

    private

    def check_first_last!(first, last)
      raise "Invalid first/last: #{first} #{last}" if first > last
    end

    def initialize_copy(clone)
      clone.days_of_week = days_of_week.dup if days_of_week
    end

  end

  class DaysOfWeek
    include Comparable

    # Create empty (no selected day)
    def initialize(attributes = {})
      self.days_mask = 0
      self.attributes = attributes
    end

    def enable(*symbolic_days)
      symbolic_days.flatten.each do |symbolic_day|
        method = "#{symbolic_day}="
        send method, true if respond_to?(method)
      end

      self
    end
    alias add enable
    alias << enable

    def disable(*symbolic_days)
      symbolic_days.flatten.each do |symbolic_day|
        method = "#{symbolic_day}="
        send method, false if respond_to?(method)
      end

      self
    end
    alias remove disable
    alias >> disable

    def include?(*symbolic_days)
      symbolic_days.each do |symbolic_day|
        method = "#{symbolic_day}?"
        included = respond_to?(method) && send(method)
        return false unless included
      end

      true
    end

    def match_date?(date)
      match_ruby_weekday? date.wday if date
    end

    def match_ruby_weekday?(wday)
      day_mask = RUBY_DAYS[wday]
      day_mask && self.days_mask_match?(day_mask)
    end

    def days
      SYMBOLIC_DAYS.select do |symbolic_day|
        include? symbolic_day
      end
    end

    def day_count
      count = 0
      SYMBOLIC_DAYS.select do |symbolic_day|
        count += 1 if include?(symbolic_day)
      end
      count
    end

    def all?
      day_count == 7
    end

    def self.none
      new
    end

    def self.all
      new.enable SYMBOLIC_DAYS
    end

    # Create a DaysOfWeek from legay TimeTable#int_day_types attribute
    def self.from_int_day_types(int_day_types)
      new.tap do |new|
        new.send "days_mask=", int_day_types
      end
    end

    def <=>(other)
      return nil unless other
      self.days_mask <=> other.days_mask
    end

    def eql?(other)
      return false unless other
      days_mask == other.days_mask
    end
    alias == eql?

    def hash
      self.days_mask
    end

    # days mask is coded with 7 bytes from 4 to 256
    # in order to work with 7 bytes we shift 2 to the right, make the logic, then shift 2 to the left
    # ex 3 shift for 0010001:
    # t << 3      : 0001000
    # t >> 4      : 0000001
    # combination : 0001001
    def shift days
      t = days_mask >> 2
      self.days_mask = (((t << (days%7)) | (t >>(7-(days%7)))) & 127) << 2
    end

    def self.days
      SYMBOLIC_DAYS
    end

    def self.each_day(&block)
      days.each(&block)
    end

    def persisted?
      false
    end

    def attributes=(attributes = {})
      attributes.each do |attribute, value|
        send "#{attribute}=", TRUE_VALUES.include?(value)
      end
    end

    protected

    attr_accessor :days_mask

    # Private representation

    TRUE_VALUES = [true, '1'].freeze

    MONDAY    = 4
    TUESDAY   = 8
    WEDNESDAY = 16
    THURSDAY  = 32
    FRIDAY    = 64
    SATURDAY  = 128
    SUNDAY    = 256
    EVERYDAY  = MONDAY | TUESDAY | WEDNESDAY | THURSDAY | FRIDAY | SATURDAY | SUNDAY

    SYMBOLIC_DAYS = %i(monday tuesday wednesday thursday friday saturday sunday).freeze
    RUBY_DAYS = [SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY].freeze

    def change_days_mask(mask, enable)
      if enable
        self.days_mask |= mask
      else
        self.days_mask &= ~mask
      end
    end

    def days_mask_match?(mask)
      (days_mask & mask) == mask
    end

    SYMBOLIC_DAYS.each do |symbolic_day|
      day_mask = const_get(symbolic_day.upcase)
      define_method "#{symbolic_day}=" do |enable|
        change_days_mask day_mask, enable
      end
      define_method symbolic_day do
        days_mask_match? day_mask
      end
      define_method "#{symbolic_day}?" do
        days_mask_match? day_mask
      end

      public "#{symbolic_day}="
      public "#{symbolic_day}"
      public "#{symbolic_day}?"
    end

  end

  class Builder

    def initialize
      @timetable = Timetable.new
    end
    attr_reader :timetable

    def self.create(&block)
      Timetable::Builder.new.dsl(&block)
    end

    def dsl(&block)
      instance_eval(&block)
      timetable
    end

    def self.date(definition)
      if definition.is_a?(String)
        # Allow to use 15/12
        if definition =~ %r{^\d+/\d+$}
          definition = "#{definition}/#{Time.zone.today.year}"
        end
        Date.parse definition
      else
        definition
      end
    end
    def date(*args); self.class.date(*args); end

    def self.date_range(*definition)
      definition = definition.map { |d| date(d) }
      Range.new(*definition)
    end
    def date_range(*args); self.class.date_range(*args); end

    DAYS = %i(monday tuesday wednesday thursday friday saturday sunday).freeze
    def self.days_of_week(definition)
      raise "Requires 7 characters: '#{definition}'" unless definition.size == 7
      DaysOfWeek.new.tap do |days_of_week|
        definition.each_char.with_index do |character, index|
          days_of_week.enable DAYS[index] unless character == '.'
        end
      end
    end

    def self.period(first, last, days_of_weeks = DaysOfWeek.all)
      days_of_weeks = days_of_week(days_of_weeks) if days_of_weeks.is_a?(String)
      Period.from date_range(first, last), days_of_weeks
    end

    def included_date(definition)
      timetable.included_dates << date(definition)
    end
    def excluded_date(definition)
      timetable.excluded_dates << date(definition)
    end

    def period(*definition)
      timetable.periods << self.class.period(*definition)
    end

  end

end
