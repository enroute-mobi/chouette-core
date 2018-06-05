class ComplianceCheckResource < ApplicationModel
  extend Enumerize

  belongs_to :compliance_check_set
  has_many :compliance_check_messages

  enumerize :status, in: %i(OK ERROR WARNING IGNORED)

  validates_presence_of :compliance_check_set
end
