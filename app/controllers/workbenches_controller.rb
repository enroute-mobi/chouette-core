# frozen_string_literal: true

class WorkbenchesController < Chouette::ResourceController
  defaults resource_class: Workbench
  include PolicyChecker

  respond_to :html, except: :destroy

  def show
    @single_workbench = @workbench.workgroup.workbenches.one?

    @wbench_refs = ReferentialDecorator.decorate(
      collection,
      context: {
        current_workbench_id: params[:id],
        workbench: @workbench
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

  def resource
    @workbench ||= current_organisation.workbenches.find params[:id]
  end

  protected

  def scope
    @workbench.all_referentials
  end

  def search
    # FIXME: should be managed by Search::Referential
    # Select workbench linked to current user by default
    params["search"] = {} if params["search"].blank?
    params["search"]["workbench_ids"] = [@workbench.id] if params["search"]["workbench_ids"].blank?

    @search ||= Search::Referential.from_params(params, workbench: @workbench)
  end

  def collection
    @collection ||= search.search scope
  end
end
