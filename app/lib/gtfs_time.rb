class GtfsTime # Temp class name
  attr_reader :hours, :minutes, :seconds
  def initialize(hours, minutes, seconds)
    @hours, @minutes, @seconds = hours, minutes, seconds
  end

  def real_hours(time_zone)
    (hours - self.class.timezone_hours(time_zone)).modulo(24)
  end

  def time(time_zone = 'UTC')
    @time ||= ::Time.new(2000, 1, 1, real_hours(time_zone), minutes, seconds, "+00:00")
  end

  def day_offset
    hours / 24
  end

  @timezone_hours = {}
  def self.timezone_hours(time_zone)
    @timezone_hours[time_zone] ||= (::Time.find_zone(time_zone).try(:utc_offset)||0) / 3600
  end

  FORMAT = /(\d{1,2}):(\d{1,2}):(\d{1,2})/

  def self.format_datetime(date_time, offset, new_timezone = 'UTC')
    return nil unless date_time
    hours = "%.2d" % (date_time.hour+(24*offset)+timezone_hours(new_timezone))
    minutes = "%.2d" % date_time.min
    seconds = "%.2d" % date_time.sec
    "#{hours}:#{minutes}:#{seconds}"
  end

  def self.parse(definition)
    if definition.to_s =~ FORMAT
      new(*[$1, $2, $3].map(&:to_i))
    end
  end
end
