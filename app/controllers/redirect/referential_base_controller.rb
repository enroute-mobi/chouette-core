# frozen_string_literal: true

module Redirect
  class ReferentialBaseController < BaseController
    include ReferentialSupport

    private

    def workbench
      @workbench ||= current_user.workbenches.find(params[:workbench_id])
    end
  end
end
