class Api::V1::WorkbenchesController < Api::V1::WorkbenchController
  inherit_resources
  defaults resource_class: Workbench

  protected

  def begin_of_association_chain
    @current_workbench.organisation
  end
end
