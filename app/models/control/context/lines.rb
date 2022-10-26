class Control::Context::Lines < Control::Context
  option :line_ids

  validate :workbench_lines_contain_selected_lines

  def selected_collection
    selected_lines.map{|l| {id: l.id, text: "#{l.name} - #{l.registration_number}" }}
  rescue
    []
  end

  private

  def workbench_lines_contain_selected_lines
    unless selected_lines.count == ids.count
      errors.add(:line_ids, :invalid)
    end
  end

  def ids
    return line_ids if line_ids.is_a? Array

    line_ids.to_s.split(',')
  end

  def selected_lines
    workbench.lines.distinct.where(id: ids)
  end

  class Run < Control::Context::Run

    def lines
      context.lines.where(id: options[:line_ids])
    end

    def routes
      context.routes.where(line: lines)
    end

    def stop_points
      context.stop_points.where(route: routes)
    end

    def stop_areas
      context.stop_areas.where(id: stop_points.select(:stop_area_id))
    end

    def journey_patterns
      context.journey_patterns.where(route: routes)
    end

    def vehicle_journeys
      context.vehicle_journeys.where(journey_pattern: journey_patterns)
    end
  end
end
