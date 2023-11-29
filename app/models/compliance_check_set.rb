class ComplianceCheckSet < ApplicationModel
  include NotifiableSupport

  has_metadata

  belongs_to :referential
  belongs_to :compliance_control_set
  belongs_to :workbench
  belongs_to :workgroup
  belongs_to :parent, polymorphic: true

  has_many :compliance_check_blocks, dependent: :destroy
  has_many :compliance_checks, dependent: :destroy

  has_many :compliance_check_resources, dependent: :destroy
  has_many :compliance_check_messages, dependent: :destroy

  validates_presence_of :workgroup

  enumerize :status, in: %w[new pending successful warning failed running aborted canceled], predicates: true

  scope :where_created_at_between, ->(period_range) do
    where('created_at BETWEEN :begin AND :end', begin: period_range.begin, end: period_range.end)
  end

  scope :unfinished, -> { where 'notified_parent_at IS NULL' }

  scope :assigned_to_slots, ->(organisation, slots) do
    joins(:compliance_control_set).merge(ComplianceControlSet.assigned_to_slots(organisation, slots))
  end

  def self.finished_statuses
    %w(successful failed warning aborted canceled)
  end
  def self.failed_statuses
    %w(failed aborted canceled)
  end

  def self.objects_pending_notification
    scope = self.where(notified_parent_at: nil).where.not(status: :aborted)
  end

  def successful?
    status.to_s == "successful"
  end

  def should_call_iev?
    compliance_checks.externals.exists?
  end

  def should_process_internal_checks_before_notifying_parent?
    # if we don't call IEV, then we will have processed internal checks right away
    compliance_checks.internals.exists? && should_call_iev?
  end

  # CHOUETTE-442
  # In a first time, updates are disabled and only log a message
  # when a ComplianceCheckSet seems to be in a bad status
  def self.abort_old
    where(
      'created_at < ? AND status NOT IN (?)',
      4.hours.ago,
      finished_statuses
    ).each do |ccs|
      Rails.logger.warn "Compliance Check Set #{ccs.id} #{ccs.name} is running for more than 4 hours"
    end
  end

  def notify_parent
    # The JAVA part is done, and want us to tell our parent
    # If we have internal chacks, we must run them beforehand
    if should_process_internal_checks_before_notifying_parent?
      perform_async(true)
    else
      do_notify_parent
    end
  end

  def do_notify_parent
    if notified_parent_at.nil?
      update(notified_parent_at: DateTime.now)
      parent&.child_change
    end
  end

  def organisation
    workbench.present? ? workbench.organisation : workgroup.owner
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
  end

  def perform_async(only_internals=false)
    enqueue_job :perform, only_internals
  end

  def perform only_internals=false
    update(started_at: DateTime.now)
    if referential.nil?
      update status: 'aborted'
      return
    end
    if should_call_iev? && !only_internals
      begin
        logger.info "ComplianceCheckSet ##{id}: calling IEV"
        Net::HTTP.get(URI("#{Rails.configuration.iev_url}/boiv_iev/referentials/validator/new?id=#{id}"))
      rescue Exception => e
        Chouette::Safe.capture "IEV server error", e
        update status: 'failed'
        notify_parent
      end
    else
      perform_internal_checks
    end
  end

  def perform_internal_checks
    update status: :running
    begin
      compliance_checks.internals.each &:process
    ensure
      update_status
      do_notify_parent
    end
  end

  def context_i18n
    context.present? ? Workgroup.compliance_control_sets_label(context) : Workgroup.compliance_control_sets_label(:manual)
  end
end
