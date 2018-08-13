class ComplianceCheckSet < ApplicationModel
  include NotifiableSupport

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

  scope :unfinished, -> { where 'notified_parent_at IS NULL' }

  scope :assigned_to_slots, ->(organisation, slots) do
    joins(:compliance_control_set).merge(ComplianceControlSet.assigned_to_slots(organisation, slots))
  end

  after_commit do
    parent&.try(:notify_state)
  end

  def self.finished_statuses
    %w(successful failed warning aborted canceled)
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

  def self.abort_old
    where(
      'created_at < ? AND status NOT IN (?)',
      4.hours.ago,
      finished_statuses
    ).update_all(status: 'aborted')
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
    organisation = workbench&.organisation
    if parent_type == "Aggregate"
      organisation ||= parent.workgroup.owner
    end
    organisation
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

  def perform_async only_internals=false
    ComplianceCheckSetWorker.perform_async_or_fail(self, only_internals) do
      update status: 'failed'
    end
  end

  def perform only_internals=false
    if referential.nil?
      update status: 'aborted'
      return
    end
    if should_call_iev? && !only_internals
      begin
        logger.info "ComplianceCheckSet ##{id}: calling IEV"
        Net::HTTP.get(URI("#{Rails.configuration.iev_url}/boiv_iev/referentials/validator/new?id=#{id}"))
      rescue Exception => e
        logger.error "IEV server error : #{e.message}"
        logger.error e.backtrace.inspect
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
