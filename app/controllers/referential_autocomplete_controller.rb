# frozen_string_literal: true

class ReferentialAutocompleteController < Chouette::ReferentialController
  skip_before_action :authorize_resource

  def lines
    @lines = referential.lines.order(:name).by_text(text).limit(50)
  end

  def companies
    scope = params.include?('line_id') ? referential.lines.find(params[:line_id]) : referential
    @companies = scope.companies.order(:name).by_text(text).limit(50)
  end

  def journey_patterns
    @journey_patterns = route.journey_patterns.by_text(text).limit(50)
  end

  def time_tables
    scope = route || referential
    @time_tables = scope.time_tables.includes(:periods, :dates).by_text(text).limit(50)
  end

  def vehicle_journeys
    @vehicle_journeys = route.vehicle_journeys.by_text(text).limit(50)
  end

  protected

  def text
    @text = params[:q]
  end

  def route
    referential.routes.find_by_id(params[:route_id])
  end
end
