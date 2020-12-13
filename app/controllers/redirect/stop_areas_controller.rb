module Redirect
  class StopAreasController < BaseController

    def show
      redirect_to default_stop_area_path!(Chouette::StopArea.find(params[:id]))
    end

  end
end
