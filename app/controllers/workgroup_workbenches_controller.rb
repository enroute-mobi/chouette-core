# frozen_string_literal: true

class WorkgroupWorkbenchesController < Chouette::WorkgroupController
  include ApplicationHelper

  defaults resource_class: Workbench
  defaults collection_name: 'workbenches', instance_name: 'workbench'

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

  def workbench_params
    return @workbench_params if @workbench_params

    workbench_params = params.require(:workbench).permit(:name, restrictions: []).with_defaults(restrictions: [])
    if params[:action] == 'create' && params[:workbench][:current_organisation] == '1'
      workbench_params[:organisation] = current_organisation
    end

    @workbench_params = workbench_params
  end
end
