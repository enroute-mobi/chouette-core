class Api::V1::ComplianceCheckSetsController < Api::V1::IbooController
  def validated
    @compliance_check_set = ComplianceCheckSet.find(params[:id])
    @compliance_check_set.update_status
  end
end
