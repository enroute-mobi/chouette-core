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

  def until(to)
    self.class.new from: from, to: to
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

  def day_count
    if from && to
      if from < to
        (to - from).to_i
      else
        0
      end
    else
      Float::INFINITY
    end
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
