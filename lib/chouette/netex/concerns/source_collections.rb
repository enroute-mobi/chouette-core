module Chouette::Netex::Concerns::SourceCollections
  def companies
    @companies ||= referential.line_referential.companies
  end

  def stop_areas
    @stop_areas ||= referential.stop_area_referential.stop_areas
  end

  def lines
    @lines ||= referential.lines.includes(:network, :company_light)
  end

  def networks
    @networks ||= referential.line_referential.networks
  end

  def routes
    @routes ||= referential.routes
  end

  def stop_points
    @stop_points ||= referential.stop_points
  end
end
