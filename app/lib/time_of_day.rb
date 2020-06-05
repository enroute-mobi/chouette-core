class TimeOfDay
  include Comparable

  attr_reader :hour, :minute, :second, :second_offset
  alias_method :min, :minute
  alias_method :sec, :second

  def initialize(hour, minute = nil, second = nil)
    @hour = (hour.is_a? String)? Integer(hour, 10) : Integer(hour)
    @minute = (minute.is_a? String)? Integer(minute || 0, 10) : Integer(minute || 0)
    @second = (second.is_a? String)? Integer(second || 0, 10) : Integer(second || 0)

    @second_offset = (@hour * 60 + @minute) * 60 + @second

    freeze
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

  def self.parse(definition)
    if PARSE_REGEX =~ definition
      hour, minute, second = $1, $2, $3
      new hour, minute, second
    end
  end

end
