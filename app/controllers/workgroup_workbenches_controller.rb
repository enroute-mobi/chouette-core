class WorkgroupWorkbenchesController < ChouetteController
  include PolicyChecker
  include ApplicationHelper

  defaults resource_class: Workbench
  defaults collection_name: 'workbenches', instance_name: 'workbench'

  belongs_to :workgroup
  helper_method :has_restriction?


  protected

  def has_restriction?(*restrictions)
    return false unless @workbench

    restrictions.all? do |restriction|
      @workbench.has_restriction? restriction
    end
  end

  private

  def resource
    super.decorate(context: { workgroup: parent })
  end

  def workbench_params
    # the next line prevents a small bug => if every restrictions are removed (unchecked) then the restrictions key doesn't even appear in params[:workbench] and thus that field isn't updated
    # related to the way the array value is passed from html form / inputs to the controller
    params[:workbench][:restrictions]=[] unless params[:workbench].key? :restrictions
    params.require(:workbench).permit(:name, :organisation_id, restrictions: [])
  end

end
