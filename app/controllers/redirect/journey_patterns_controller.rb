# frozen_string_literal: true

module Redirect
  class JourneyPatternsController < ReferentialBaseController
    def journey_pattern
      referential.journey_patterns.find(params[:id])
    end

    def show
      redirect_to workbench_referential_line_route_journey_patterns_path(
        workbench,
        referential,
        journey_pattern.route.line,
        journey_pattern.route
      )
    end
  end
end
