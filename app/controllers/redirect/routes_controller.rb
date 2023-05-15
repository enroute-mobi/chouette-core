module Redirect
  class RoutesController < BaseController
    def referential
      Referential.find(params[:referential_id])
    end

    def route
      referential.switch
      Chouette::Route.find(params[:id])
    end

    def show
      redirect_to default_route_path(referential, route)
    end
  end
end
