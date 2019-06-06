module ReferentialAudit::Concerns::JourneyPatternBase
  def record_name(record, output)
    record_name = "JourneyPattern ##{record.id}"
    if output == :html
      url = url_for([@referential, record.line, record.route, :journey_patterns_collection, host: base_host])
      record_name = link_to record_name, url
    end
    record_name
  end
end
