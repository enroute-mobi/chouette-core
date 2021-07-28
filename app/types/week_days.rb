class WeekDays < ActiveRecord::Type::Value
  class InvalidValue < StandardError; end

  def type
    :string
  end

  def cast(value)
    check_and_format_value(value)
  end

  def deserialize(value)
    value = PG::TextDecoder::Array.new.decode(value)

    check_and_format_value(value)
  end

  def serialize(value)
    days = Timetable::DaysOfWeek::SYMBOLIC_DAYS.map do |symbolic_day|
      value.days.include?(symbolic_day) ? symbolic_day.to_s : '.'
    end

    PG::TextEncoder::Array.new.encode(days)
  end

  private

  def check_and_format_value(value = [])
    value = value.map(&:first).join('')
    value = value.ljust(7, '.')

    raise InvalidValue.new("value (#{value}) should have at most 7 characters") unless value.length == 7

    Timetable::Builder.days_of_week(value)
  end
end