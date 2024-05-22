module Redirect
  class StopAreasController < BaseController

    def show
      redirect_to workbench_stop_area_referential_path!(Chouette::StopArea.find(params[:id]))
    end

  end
end
