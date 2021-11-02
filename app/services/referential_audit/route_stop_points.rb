class ReferentialAudit
  class RouteStopPoints < Base
    include ReferentialAudit::Concerns::RouteBase

    def message(record, output: :console)
      "#{record_name(record, output)} has stop_point(s) with the same position"
    end

    def find_faulty
      Chouette::Route.select('routes.id').joins(:stop_points).group('routes.id, stop_points.position').having('COUNT(*) >= 2').uniq
    end
  end
end
