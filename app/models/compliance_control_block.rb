class ComplianceControlBlock < ActiveRecord::Base
  include StifTransportModeEnumerations
  include StifTransportSubmodeEnumerations

  belongs_to :compliance_control_set
  has_many :compliance_controls, dependent: :destroy

  store_accessor :condition_attributes,
    :transport_mode,
    :transport_submode

  validates :transport_mode, presence: true
  validates :compliance_control_set, presence: true

  validate def unique_transport_mode_submode_combination
    same_cc_block = ComplianceControlBlock.where("compliance_control_set_id = ? AND condition_attributes->'transport_mode' = ? AND condition_attributes->'transport_submode' = ?", self.compliance_control_set_id, self.transport_mode, self.transport_submode)
    return true if same_cc_block.empty?
    errors.add(:duplicate, I18n.t('activerecord.errors.models.compliance_control_block.attributes.condition_attributes.duplicate'))
  end

  def name
    ApplicationController.helpers.transport_mode_text(self)
  end

end
