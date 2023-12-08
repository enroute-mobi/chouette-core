# frozen_string_literal: true

class Redirect::BaseController < Chouette::UserController
  include DefaultPathHelper
  rescue_from DefaultPathHelper::NoDefaultWorkbenchError, with: :not_default_workbench

  private

  def not_default_workbench
    Rails.logger.warn "Can't redirect User ##{current_user.id} to Workbench resource"
    redirect_to root_path
  end
end
