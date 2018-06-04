class ComplianceCheck < ApplicationModel
  include ComplianceItemSupport

  self.inheritance_column = nil

  extend Enumerize
  belongs_to :compliance_check_set
  belongs_to :compliance_check_block

  enumerize :criticity, in: %i(warning error), scope: true, default: :warning
  validates :criticity, presence: true
  validates :name, presence: true
  validates :code, presence: true
  validates :origin_code, presence: true

  scope :internals, ->{ where iev_enabled_check: false }
  scope :externals, ->{ where iev_enabled_check: true }

  delegate :referential, :parent, to: :compliance_check_set

  def control_class
    compliance_control_name.present? ? compliance_control_name.constantize : nil
  end

  delegate :predicate, to: :control_class, allow_nil: true
  delegate :prerequisite, to: :control_class, allow_nil: true

  def internal?
    !iev_enabled_check
  end

  def process
    raise "This check should be handled by the third-party JAVA app" unless internal?
    raise "Control Class is missing" unless control_class.present?

    control_class.check self
  end
end
