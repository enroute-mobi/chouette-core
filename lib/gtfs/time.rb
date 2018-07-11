module GTFS
  class Time
    attr_reader :hours, :minutes, :seconds
    def initialize(hours, minutes, seconds)
      @hours, @minutes, @seconds = hours, minutes, seconds
    end

    def real_hours
      hours.modulo(24)
    end

    def time
      @time ||= ::Time.new(2000, 1, 1, real_hours, minutes, seconds, "+00:00")
    end

    def day_offset
      hours / 24
    end

    FORMAT = /(\d{1,2}):(\d{2}):(\d{2})/

    def self.format_datetime (date_time, offset)
      "#{date_time.hour+(24*offset)}:#{date_time.min}:#{date_time.sec}"
    end

    def self.parse(definition)
      if definition.to_s =~ FORMAT
        new *[$1, $2, $3].map(&:to_i)
      end
    end
  end
end
