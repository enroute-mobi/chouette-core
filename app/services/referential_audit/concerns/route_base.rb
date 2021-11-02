module ReferentialAudit::Concerns::RouteBase
  def record_name(record, output)
    record_name = "Route ##{record.id}"
    if output == :html
      url = url_for([@referential, record.line, record.route, host: base_host])
      record_name = link_to record_name, url
    end
    record_name
  end
end
