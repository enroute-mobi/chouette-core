class AutocompleteCalendarsController < ChouetteController
  respond_to :json, :only => [:autocomplete]
  
  belongs_to :workgroup

  def autocomplete
    scope = workgroup.calendars.where('organisation_id = ? OR shared = ?', current_organisation.id, true)
    @calendars = scope.search(params[:q]).result.paginate(page: params[:page])
  end

  protected

  alias_method :workgroup, :parent
end
