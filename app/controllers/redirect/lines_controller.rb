module Redirect
  class LinesController < BaseController

    def show
      redirect_to default_line_path!(Chouette::Line.find(params[:id]))
    end

  end
end
