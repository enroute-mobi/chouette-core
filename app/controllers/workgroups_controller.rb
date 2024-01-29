# frozen_string_literal: true

class WorkgroupsController < Chouette::ResourceController
  defaults resource_class: Workgroup

  include PolicyChecker
  before_action :authorize_resource, only: %i[setup_deletion remove_deletion]

  def create
    @workgroup = Workgroup.create_with_organisation current_organisation, workgroup_params
    redirect_to(@workgroup)
  rescue ActiveRecord::RecordInvalid
    @workgroup = Workgroup.new workgroup_params
    render :new
  end

  def show
    show! do |format|
      format.html {
        @workbenches = WorkgroupWorkbenchDecorator.decorate(
          @workgroup.workbenches.order('created_at DESC').paginate(page: params[:page]),
          context: {
            workgroup: @workgroup
          }
        )
      }
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
    unless resource.update workgroup_params
      render :edit
    else
      flash[:success] = t('workgroups.edit.success')
      redirect_to resource
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

  protected

  def scope
    @scope ||= current_organisation.workgroups
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
      :nightly_aggregate_enabled, :nightly_aggregate_time, :nightly_aggregate_days, :nightly_aggregate_notification_target,
      :transport_modes_as_json,
      workbenches_attributes: [
        :id,
        :locked_referential_to_aggregate_id,
        :priority,
      ]
    )
  end

  def resource
    @workgroup ||= if params[:id]
      current_organisation.workgroups.find(params[:id]).decorate
    else
      current_organisation.workgroups.build
    end
  end

  alias current_workgroup resource
end
