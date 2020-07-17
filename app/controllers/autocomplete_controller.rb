class AutocompleteController < ChouetteController

  belongs_to :workbench, :optional => true do
    belongs_to :referential do
      belongs_to :line, :parent_class => Chouette::Line, :optional => true
    end
  end

  respond_to :json, only: [:lines]

  def lines
    return [] if !params[:q]

    @lines = if workbench
      workbench.line_referential.lines.by_text("%#{params[:q]}%")
    elsif referential
      Apartment::Tenant.switch!(referential.slug)
      referential.lines.by_text("%#{params[:q]}%")
    else
      []
    end
  end

  protected

  def workbench
    @workbench ||= params[:workbench_id] ? Workbench.find(params[:workbench_id]) : nil
  end

  def referential
    @referential ||= params[:referential_id] ? Referential.find(params[:referential_id]) : nil
  end

end
