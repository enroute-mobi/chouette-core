module Redirect
  class JourneyPatternsController < BaseController
    def referential
      Referential.find(params[:referential_id])
    end

    def journey_pattern
      referential.switch
      Chouette::JourneyPattern.find(params[:id])
    end

    def show
      redirect_to default_journey_pattern_path(referential, journey_pattern)
    end
  end
end
