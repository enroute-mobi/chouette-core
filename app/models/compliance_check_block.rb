class ComplianceCheckBlock < ApplicationModel
  include NetexTransportModeEnumerations
  include StifTransportSubmodeEnumerations

  belongs_to :compliance_check_set

  has_many :compliance_checks, dependent: :nullify

  store_accessor :condition_attributes,
    :transport_mode,
    :transport_submode

end
