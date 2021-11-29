class ReferentialAudit
  class DuplicatedPeriodForTimeTable < Base
    include ReferentialAudit::Concerns::RouteBase

    def message(record, output: :console)
      "#{record_name(record, output)} is a duplicated period for timetable #{record.time_table_id}"
    end

    def find_faulty
      Chouette::TimeTablePeriod.joins("inner join time_table_periods as brother on time_table_periods.time_table_id = brother.time_table_id and time_table_periods.id <> brother.id").where("time_table_periods.period_start = brother.period_start AND time_table_periods.period_end = brother.period_end")
    end
  end
end
