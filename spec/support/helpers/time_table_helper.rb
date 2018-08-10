module Support::TimeTableHelper
  def get_dates(dates, in_out:)
    dates.reduce([]) do |array, d|
      binding.pry
      array << d.date if d.in_out == in_out
      array
    end
  end
end