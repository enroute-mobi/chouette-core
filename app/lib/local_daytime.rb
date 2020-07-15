class LocalDaytime
  def initialize val=nil
    if val
      @time = val.to_time.utc
    else
      @time = Time.now
    end
    @hours ||= @time.hour
    @minutes ||= @time.min
    @seconds ||= @time.sec

    @seconds_since_midnight ||= @seconds + @minutes * 60 + @hours * 3600
  end

  attr_reader :seconds_since_midnight

  def -(other)
    seconds_since_midnight - other.seconds_since_midnight
  end

  def self.convert_to_db val
    "2000/01/01 #{val} UTC"
  end

  def strftime(*args)
    @time.localtime.strftime(*args)
  end
end
