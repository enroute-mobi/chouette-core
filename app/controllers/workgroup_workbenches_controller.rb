# frozen_string_literal: true

class WorkgroupWorkbenchesController < Chouette::WorkgroupController
  include ApplicationHelper

  defaults resource_class: Workbench
  defaults collection_name: 'workbenches', instance_name: 'workbench'

  def show
    show! do |format|
      format.html do
        @workbench_sharings = Workbench::SharingDecorator.decorate(
          @workbench.sharings,
          context: { workgroup: @workgroup, workbench: @workbench }
        )
      end
    end
  end

  def create
    create! { workbench_path }
  end

  def update
    update! { workbench_path }
  end

  private

  def workbench_path
    workgroup_workbench_path(workgroup, @workbench)
  end

  def resource
    WorkgroupWorkbenchDecorator.decorate(super, context: { workgroup: workgroup })
  end

  def workbench_params # rubocop:disable Metrics/MethodLength
    return @workbench_params if @workbench_params

    workbench_params = params.require(:workbench).permit(
      :name,
      :hidden,
      restrictions: []
    ).with_defaults(
      restrictions: []
    )
    if params[:action] == 'create' && params[:workbench][:current_organisation] == '1'
      workbench_params[:organisation] = current_organisation
    end

    @workbench_params = workbench_params
  end
end
