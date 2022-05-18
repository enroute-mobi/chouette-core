class WeekDays < ActiveRecord::Type::Value
  class InvalidValue < StandardError; end

  def type
    'bit(7)'
  end

  def cast(value)
    if value.is_a?(String)
      check_and_format_value(value)
    else
      value
    end
  end

  def deserialize(value)
    check_and_format_value(value)
  end

  def serialize(value)
    Timetable::DaysOfWeek::SYMBOLIC_DAYS.map do |symbolic_day|
      value.days.include?(symbolic_day) ? '1' : '0'
    end.join('')
  end

  private

  def check_and_format_value(value)
    raise InvalidValue.new("value (#{value}) should have at most 7 characters") unless value.length == 7

    Timetable::Builder.days_of_week(
      value.gsub('0', '.')
    )
  end
end