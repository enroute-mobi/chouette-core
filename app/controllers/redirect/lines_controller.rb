module Redirect
  class LinesController < BaseController

    def show
      redirect_to workbench_line_referential_lines_path!(Chouette::Line.find(params[:id]))
    end

  end
end
