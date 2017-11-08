class Api::V1::ComplianceCheckSetsController < Api::V1::IbooController
  def validated
    @compliance_check_set = ComplianceCheckSet.find(params[:id])

    if @compliance_check_set.update_status
      render :validated
    else
      render json: {
        status: "error",
        messages: @compliance_check_set.errors.full_messages
      }
    end
  end
end
