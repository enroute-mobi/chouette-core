module ReferentialAudit::Concerns::TimeTableBase
  def record_name(record, output)
    record_name = "TimeTable ##{record.time_table_id}"
    if output == :html
      url = url_for([@referential, record.time_table_id, host: base_host])
      record_name = link_to record_name, url
    end
    record_name
  end
end
