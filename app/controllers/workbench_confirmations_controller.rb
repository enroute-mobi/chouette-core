# frozen_string_literal: true

class WorkbenchConfirmationsController < Chouette::ResourceController
  defaults resource_class: Workbench::Confirmation, singleton: true

  def create
    create! do |success, _|
      success.html do
        workbench = @workbench_confirmation.workbench
        flash[:notice] = t('.success', workbench: workbench.name, workgroup: workbench.workgroup.name)
        redirect_to workbench_path workbench
      end
    end
  end

  protected

  def begin_of_association_chain
    current_organisation
  end

  def authorize_resource_class
    authorize_policy(parent_policy, :workbench_confirm?, Workbench)
  end

  def workbench_confirmation_params
    params.require(:workbench_confirmation).permit(
      :invitation_code
    )
  end
end
