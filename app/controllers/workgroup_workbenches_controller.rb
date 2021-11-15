class WorkgroupWorkbenchesController < ChouetteController
  include PolicyChecker
  include ApplicationHelper

  defaults resource_class: Workbench
  defaults collection_name: 'workbenches', instance_name: 'workbench'

  belongs_to :workgroup
  helper_method :has_restriction?

  def create
    @workbench = Workbenches::CreateWithoutOrganisation.call(
      workbench_params.slice(:name).merge(workgroup: parent)
    )

    create! { workbench_path }
  end

  def update
    update! { workbench_path }
  end

  protected

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
    workgroup_workbench_path(parent, @workbench)
  end

  def resource
    WorkgroupWorkbenchDecorator.decorate(super, context: { workgroup: parent })
  end

  def workbench_params
    # the next line prevents a small bug => if every restrictions are removed (unchecked) then the restrictions key doesn't even appear in params[:workbench] and thus that field isn't updated
    # related to the way the array value is passed from html form / inputs to the controller
    params.require(:workbench).permit(:name, :organisation_id, restrictions: []).with_defaults(restrictions: [])
  end

end
