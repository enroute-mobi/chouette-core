class ReferentialAutocompleteController < ChouetteController
  include ReferentialSupport

  def lines
    @lines = referential.lines.order(:name).by_text(text)
  end

  def companies
    scope = params.include?('line_id') ? referential.lines.find(params[:line_id]) : referential
    @companies = scope.companies.order(:name).by_text(text)
  end

  def journey_patterns
    @journey_patterns = route.journey_patterns.by_text(text)
  end

  def time_tables
    scope = route || referential
    @time_tables = scope.time_tables.by_text(text)
  end

  def vehicle_journeys
    @vehicle_journeys = route.vehicle_journeys.by_text(text)
  end

  protected

  def text
    @text = params[:q]
  end

  def route
    referential.routes.find_by_id(params[:route_id])
  end
end