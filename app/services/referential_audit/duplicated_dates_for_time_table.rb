class ReferentialAudit
  class DuplicatedDatesForTimeTable < Base
    include ReferentialAudit::Concerns::RouteBase

    def message(record, output: :console)
      "#{record_name(record, output)} is a duplicated date for timetable #{record.time_table_id}"
    end

    def find_faulty
      Chouette::TimeTableDate.joins("inner join time_table_dates as brother on time_table_dates.time_table_id = brother.time_table_id and time_table_dates.id <> brother.id").where("time_table_dates.date = brother.date AND time_table_dates.in_out = brother.in_out")
    end
  end
end
