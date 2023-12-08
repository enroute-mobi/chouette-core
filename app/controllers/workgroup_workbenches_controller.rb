# frozen_string_literal: true

class WorkgroupWorkbenchesController < Chouette::WorkgroupController
  include PolicyChecker
  include ApplicationHelper

  defaults resource_class: Workbench
  defaults collection_name: 'workbenches', instance_name: 'workbench'

  belongs_to :workgroup
  helper_method :has_restriction?

  def create
    @workbench = workgroup.workbenches.create workbench_params
    create! { workbench_path }
  end

  def update
    update! { workbench_path }
  end

  protected

  alias workgroup parent

  def has_restriction?(*restrictions)
    return false unless @workbench

    restrictions.all? do |restriction|
      @workbench.has_restriction? restriction
    end
  end

  # A specific policy handles this controller, since the use cases are different between WorkgroupWorkbenchesController (controller that handles workbench administration related to workgroup)
  # and WorkbenchesController (workbench management / edtioon / unrelated to administration)
  def authorize_resource
    authorize resource, policy_class: WorkgroupWorkbenchPolicy
  end

  def authorize_resource_class
    authorize resource_class, policy_class: WorkgroupWorkbenchPolicy
  end

  private

  def workbench_path
    workgroup_workbench_path(workgroup, @workbench)
  end

  def resource
    WorkgroupWorkbenchDecorator.decorate(super, context: { workgroup: workgroup })
  end

  def workbench_params
    params.require(:workbench).permit(:name, restrictions: []).with_defaults(restrictions: [])
  end
end
