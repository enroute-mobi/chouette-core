class AutocompleteController < ChouetteController
  respond_to :json, only: [:lines]

  def lines
     return [] unless params[:q] && scope
     @lines = scope.lines.by_text("%#{params[:q]}%")
   end

  protected

  def scope
     workbench || referential
   end

   def workbench
     @workbench ||= current_organisation.workbenches.find(params[:workbench_id]) if params[:workbench_id]
   end

   def referential
     @referential ||= current_organisation.referentials.find(params[:referential_id]) if params[:referential_id]
   end

end
