class ComplianceCheckSet < ActiveRecord::Base
  extend Enumerize

  belongs_to :referential
  belongs_to :compliance_control_set
  belongs_to :workbench
  belongs_to :parent, polymorphic: true

  has_many :compliance_check_blocks
  has_many :compliance_checks

  has_many :compliance_check_resources
  has_many :compliance_check_messages

  enumerize :status, in: %w[new pending successful warning failed running aborted canceled]

  scope :where_created_at_between, ->(period_range) do
    where('created_at BETWEEN :begin AND :end', begin: period_range.begin, end: period_range.end)
  end

  def update_status
  end
end
