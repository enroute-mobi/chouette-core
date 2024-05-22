# frozen_string_literal: true

module Redirect
  class BaseController < Chouette::UserController

    private

    def not_default_workbench
      Rails.logger.warn "Can't redirect User ##{current_user.id} to Workbench resource"
      redirect_to root_path
    end
  end
end
