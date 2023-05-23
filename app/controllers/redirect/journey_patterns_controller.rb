module Redirect
  class JourneyPatternsController < BaseController
    include ReferentialSupport

    def journey_pattern
      referential.journey_patterns.find(params[:id])
    end

    def show
      redirect_to referential_line_route_journey_patterns_collection_path referential, journey_pattern.route.line,
                                                                          journey_pattern.route
    end
  end
end
