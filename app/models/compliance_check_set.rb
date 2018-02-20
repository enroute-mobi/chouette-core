class ComplianceCheckSet < ActiveRecord::Base
  extend Enumerize
  has_paper_trail class_name: 'PublicVersion'

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
    statuses = compliance_check_resources.map do |resource|
      case resource.status
      when 'ERROR'
        return update(status: 'failed')
      when 'WARNING'
        return update(status: 'warning')
      else
        resource.status
      end
    end

    if statuses_ok_or_ignored?(statuses)
      return update(status: 'successful')
    end

    true
  end

  private

  def statuses_ok_or_ignored?(statuses)
    uniform_statuses = statuses.uniq

    (
      # All statuses OK
      uniform_statuses.length == 1 &&
        uniform_statuses.first == 'OK'
    ) ||
    (
      # Statuses OK or IGNORED
      uniform_statuses.length == 2 &&
        uniform_statuses.include?('OK') &&
        uniform_statuses.include?('IGNORED')
    )
  end
end
