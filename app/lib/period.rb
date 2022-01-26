class Period < Range

  alias_method :start_date, :begin
  alias_method :from, :begin

  alias_method :end_date, :end
  alias_method :to, :end

  def initialize(from: nil, to: nil)
    super from, to
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

  def middle
    return nil if infinite?
    from + day_count / 2
  end

  # period.during(14.days)
  # period.during(1.month)
  # Period.from(Date.today).during(14.days)
  # Period.until(Date.today).during(14.days)
  def during(duration)
    in_days = duration.respond_to?(:in_days) ? duration.in_days : duration / 1.day

    if from
      self.class.new from: from, to: from + in_days
    elsif to
      self.class.new from: to - in_days, to: to
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
    return false unless from || to
    return from <= to if from && to

    true
  end

  def empty?
    from.nil? && to.nil?
  end

  def infinite?
    from.nil? || to.nil?
  end

  def day_count
    unless infinite?
      if from < to
        (to - from).to_i
      else
        0
      end
    else
      Float::INFINITY
    end
  end

  def duration
    return nil if infinite?
    day_count.days
  end

  def time_range
    range_begin = from&.to_datetime
    range_end = to ? (to+1).to_datetime : nil

    range_begin..range_end
  end

  def infinite_time_range
    range = time_range

    range_begin = range.begin || -Float::INFINITY
    range_end = range.end || Float::INFINITY

    Range.new range_begin, range_end
  end

  def include?(date)
    date = date.to_date if date.respond_to?(:to_date)

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

end
