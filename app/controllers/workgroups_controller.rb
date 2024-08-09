# frozen_string_literal: true

class WorkgroupsController < Chouette::ResourceController
  defaults resource_class: Workgroup, collection_name: :owned_workgroups

  def create
    @workgroup = Workgroup.create_with_organisation current_organisation, workgroup_params
    redirect_to(@workgroup)
  rescue ActiveRecord::RecordInvalid
    @workgroup = Workgroup.new workgroup_params
    render :new
  end

  def show
    show! do |format|
      format.html do
        @workbenches = WorkgroupWorkbenchDecorator.decorate(
          @workgroup.workbenches.order('created_at DESC').paginate(page: params[:page]),
          context: {
            workgroup: @workgroup
          }
        )
      end
    end
  end

  def index
    index! do |format|
      format.html do
        @workgroups = WorkgroupDecorator.decorate(
          collection
        )
      end
    end
  end

  def update
    if resource.update workgroup_params
      flash[:success] = t('workgroups.edit.success')
      redirect_to resource
    else
      render :edit
    end
  end

  def setup_deletion
    resource.setup_deletion!
    redirect_to resource
  end

  def remove_deletion
    resource.remove_deletion!
    redirect_to resource
  end

  def policy_context_class
    if current_workgroup
      Policy::Context::Workgroup
    else
      Policy::Context::User
    end
  end

  protected

  def scope
    @scope ||= current_organisation.owned_workgroups
  end

  def search
    @search ||= Search::Workgroup.from_params(params)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def workgroup_params
    params.require(:workgroup).permit(
      :name,
      :description,
      :enable_purge_merged_data,
      :maximum_data_age,
      :nightly_aggregate_notification_target,
      :transport_modes_as_json,
      workbenches_attributes: %i[
        id
        locked_referential_to_aggregate_id
        priority
      ],
      aggregate_schedulings_attributes: %i[id aggregate_time aggregate_days force_daily_publishing value
                                           _destroy]
    )
  end

  def resource
    @workgroup ||= if params[:id] # rubocop:disable Naming/MemoizedInstanceVariableName
                     current_organisation.owned_workgroups.find(params[:id]).decorate
                   else
                     current_organisation.owned_workgroups.build
                   end
  end

  def current_workgroup
    return nil unless params[:id]

    resource
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
