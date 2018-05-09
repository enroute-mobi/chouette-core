class ComplianceCheckSet < ApplicationModel
  extend Enumerize

  has_metadata

  belongs_to :referential
  belongs_to :compliance_control_set
  belongs_to :workbench
  belongs_to :parent, polymorphic: true

  has_many :compliance_check_blocks, dependent: :destroy
  has_many :compliance_checks, dependent: :destroy

  has_many :compliance_check_resources, dependent: :destroy
  has_many :compliance_check_messages, dependent: :destroy

  enumerize :status, in: %w[new pending successful warning failed running aborted canceled]

  scope :where_created_at_between, ->(period_range) do
    where('created_at BETWEEN :begin AND :end', begin: period_range.begin, end: period_range.end)
  end

  scope :blocked, -> { where('created_at < ? AND status = ?', 4.hours.ago, 'running') }

  def self.finished_statuses
    %w(successful failed warning aborted canceled)
  end

  def self.abort_old
    where(
      'created_at < ? AND status NOT IN (?)',
      4.hours.ago,
      finished_statuses
    ).update_all(status: 'aborted')
  end

  def notify_parent
    if parent
      # parent.child_change
      update(notified_parent_at: DateTime.now)
    end
  end

  def organisation
    workbench.organisation
  end

  def human_attribute_name(*args)
    self.class.human_attribute_name(*args)
  end

  def update_status
    status =
      if compliance_check_resources.where(status: 'ERROR').count > 0
        'failed'
      elsif compliance_check_resources.where(status: ["WARNING", "IGNORED"]).count > 0
        'warning'
      elsif compliance_check_resources.where(status: "OK").count == compliance_check_resources.count
        'successful'
      end

    attributes = {
      status: status
    }

    if self.class.finished_statuses.include?(status)
      attributes[:ended_at] = Time.now
    end

    update attributes
    import_resource&.next_step
  end

  def import_resource
    referential&.import_resources.main_resources.last
  end


end
