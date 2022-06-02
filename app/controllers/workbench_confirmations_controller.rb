class WorkbenchConfirmationsController < ChouetteController
  defaults resource_class: Workbench::Confirmation, singleton: true

  include PolicyChecker

  def create
    create! do |success, _|
      success.html { workbench_path @workbench_confirmation.workbench }
    end
  end

  protected

  def workbench_confirmation_params
    params.require(:workbench_confirmation).permit(
      :invitation_code
    )
  end
end
