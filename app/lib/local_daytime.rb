class LocalDaytime
  def initialize val=nil
    if val
      @time = val.to_time.utc
      if val.is_a?(String)
        @time =  val.to_time.utc
        @hours, @minutes, @seconds = val.gsub(/"/, '').split(':').map(&:to_i)
      end
    else
      @time = Time.now
    end
    @hours ||= @time.hour
    @minutes ||= @time.min
    @seconds ||= @time.sec
  end

  def seconds_since_midnight
    @seconds + @minutes * 60 + @hours * 3600
  end

  def -(other)
    seconds_since_midnight - other.seconds_since_midnight
  end

  def self.convert_to_db val
    "2000/01/01 #{val} UTC"
  end

  def strftime(*args)
    @time.localtime.strftime *args
  end
end
