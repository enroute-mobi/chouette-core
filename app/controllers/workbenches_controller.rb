class WorkbenchesController < ChouetteController
  defaults resource_class: Workbench
  include PolicyChecker

  respond_to :html, except: :destroy

  def index
    redirect_to dashboard_path
  end

  def show
    @wbench_refs = ReferentialDecorator.decorate(
      collection,
      context: {
        current_workbench_id: params[:id],
        workbench: @workbench,
        line_referential: @line_referential
      }
    )
  end

  def delete_referentials
    referentials = resource.referentials.where(id: params[:referentials])
    referentials.each do |referential|
      next unless policy(referential).destroy?

      referential.enqueue_job :destroy
      referential.update_attribute(:ready, false)
    end
    flash[:notice] = t('notice.referentials.deleted')
    redirect_to resource
  end

  private

  def workbench_params
    params.require(:workbench).permit(compliance_control_set_ids: @workbench.workgroup.compliance_control_sets_by_workbench.keys)
  end

  def resource
    @workbench = current_organisation.workbenches.find params[:id]
  end

  protected

  def scope
    @workbench.all_referentials
  end

  def search
    @search ||= Search::Workbench.new(scope, params, workbench: @workbench)
  end

  delegate :collection, to: :search

end
