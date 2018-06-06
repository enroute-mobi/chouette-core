class AutocompleteCompaniesController < ApplicationController
  respond_to :json, :only => [:autocomplete]

  def autocomplete
    scope = Chouette::Company.where(line_referential_id: current_organisation.line_referential_memberships.pluck(:line_referential_id))
    @companies = scope.search(params[:q]).result.paginate(page: params[:page])
  end
end
