module Support::TimeTableHelper
  def get_dates(dates, in_out:)
    dates.select{|d| d.in_out == in_out}.map &:date
  end
end
