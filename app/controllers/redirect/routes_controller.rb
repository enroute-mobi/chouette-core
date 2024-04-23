# frozen_string_literal: true

module Redirect
  class RoutesController < ReferentialBaseController
    def route
      referential.routes.find(params[:id])
    end

    def show
      redirect_to workbench_referential_line_route_path workbench, referential, route.line, route
    end
  end
end
