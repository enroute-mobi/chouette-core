module Redirect
  class CompaniesController < BaseController

    def show
      redirect_to workbench_line_referential_companies_path!(Chouette::Company.find(params[:id]))
    end

  end
end
