class ComplianceControlSet < ApplicationModel
  has_metadata

  belongs_to :organisation
  has_many :compliance_control_blocks, dependent: :destroy
  has_many :compliance_controls, dependent: :destroy

  validates :name, presence: true
  validates :organisation, presence: true

  scope :where_updated_at_between, ->(period_range) do
    where('updated_at BETWEEN :begin AND :end', begin: period_range.begin, end: period_range.end)
  end

  scope :assigned_to_slots, ->(organisation, slots) do
    if !slots.present? || slots.all?(&:empty?)
      all
    else
      ids = self.pluck(:id)
      kept_ids = []
      organisation.workbenches.select do |w|
        kept_ids += (w.owner_compliance_control_set_ids||{}).values_at(*slots).flatten
      end
      ids = ids & kept_ids.uniq.map(&:to_i).compact
      self.where(id: ids)
    end
  end

  def truncated_name
    name&.truncate(150)
  end

  def assignments current_user
    out = []
    current_user.organisation.workbenches.each do |workbench|
      vals = workbench.owner_compliance_control_set_ids&.select{|k, v| v == self.id.to_s}&.keys || []
      out += Workgroup.send(:compliance_control_sets_labels, vals).values
    end
    out
  end

  def export
    out = attributes.symbolize_keys.slice(:name)
    out.update(compliance_controls: compliance_controls.where(compliance_control_block_id: nil).map(&:export))
    out.update(compliance_control_blocks: compliance_control_blocks.map(&:export))
    out
  end

  def import(data)
    self.class.transaction do
      (data[:compliance_controls] || []).each do |compliance_control_check_data|
        compliance_controls << ComplianceControl.import(compliance_control_check_data, control_set: self)
      end

      (data[:compliance_control_blocks] || []).each do |compliance_control_block_data|
        compliance_control_blocks << ComplianceControlBlock.import(compliance_control_block_data, control_set: self)
      end
    end
  end
end
