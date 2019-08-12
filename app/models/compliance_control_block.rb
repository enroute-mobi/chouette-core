class ComplianceControlBlock < ApplicationModel
  include ComplianceBlockSupport

  belongs_to :compliance_control_set
  has_many :compliance_controls, dependent: :destroy

  validates_uniqueness_of :condition_attributes, scope: :compliance_control_set_id
  validates :compliance_control_set, presence: true

  alias_method :name, :block_name

  def export
    out = attributes.symbolize_keys.slice(:name, :condition_attributes)
    out.update(compliance_control_checks: compliance_controls.map(&:export))
    out
  end
end
