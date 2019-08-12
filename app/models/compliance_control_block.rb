class ComplianceControlBlock < ApplicationModel
  include ComplianceBlockSupport

  belongs_to :compliance_control_set
  has_many :compliance_controls, dependent: :destroy

  validates_uniqueness_of :condition_attributes, scope: :compliance_control_set_id
  validates :compliance_control_set, presence: true

  alias_method :name, :block_name

  def self.import(data, control_set:)
    controls = data.delete(:compliance_controls) || []
    create!({compliance_control_set_id: control_set.id}.update(data)).tap do |block|
      controls.each do |control_data|
        block.compliance_controls << ComplianceControl.import(control_data, control_set: control_set, control_block: block)
      end
    end
  end

  def export
    out = attributes.symbolize_keys.slice(:name, :condition_attributes)
    out.update(compliance_controls: compliance_controls.map(&:export))
    out
  end
end
