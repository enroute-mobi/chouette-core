module Redirect
  class CompaniesController < BaseController

    def show
      redirect_to default_company_path!(Chouette::Company.find(params[:id]))
    end

  end
end
