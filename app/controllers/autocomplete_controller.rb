class AutocompleteController < ChouetteController
  respond_to :json, only: [:lines, :companies, :line_providers]

  def lines
    @lines = scope.lines.order(:name).by_text(text)
  end

  def companies
    @companies = scope.companies.order(:name).by_text(text)
  end

  def line_providers
    @line_providers = scope.line_providers.order(:short_name).by_text(text)
  end

  protected

  def text
    @text = params[:q]
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
