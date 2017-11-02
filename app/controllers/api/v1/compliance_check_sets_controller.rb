class Api::V1::ComplianceCheckSetsController < Api::V1::IbooController
  defaults resource_class: ComplianceCheckSet

  def validated
  end
end
