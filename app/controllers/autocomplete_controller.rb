class AutocompleteController < ChouetteController
  respond_to :json, only: [:lines, :companies, :line_providers]

  def lines
    @lines = find_resources_by_text(:lines)
  end

  def companies
    @companies = find_resources_by_text(:companies)
  end

  def line_providers
    @line_providers = find_resources_by_text(:line_providers)
  end

  protected

  def find_resources_by_text collection_name
    collection = scope.send(collection_name)
    return [] unless scope
    return collection unless params[:q]
    collection.by_text("%#{params[:q]}%")
  end

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
