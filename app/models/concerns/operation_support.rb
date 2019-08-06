module OperationSupport
  extend ActiveSupport::Concern

  included do |into|
    into.extend Enumerize
    into.include ProfilingSupport

    enumerize :status, in: %w[new pending successful failed running canceled], default: :new
    scope :successful, ->{ where status: :successful }
    scope :for_referential, ->(referential){ where('referential_ids @> ARRAY[?]::bigint[]', referential.id) }

    has_array_of :referentials, class_name: 'Referential'
    belongs_to :new, class_name: 'Referential'
    has_many :publications, as: :parent, dependent: :destroy

    validate :has_at_least_one_referential, :on => :create
    validate :check_other_operations, :on => :create, unless: :profile?

    into.extend ClassMethods
  end

  DEFAULT_KEEP_OPERATIONS = 20

  module ClassMethods
    def keep_operations=(value)
      @keep_operations = [value, 1].max # we cannot keep less than 1 operation
    end

    def keep_operations
      @keep_operations ||= DEFAULT_KEEP_OPERATIONS
    end

    def finished_statuses
     %w(successful failed canceled)
    end
  end

  def name
    created_at.l(format: :short_with_time)
  end

  def full_names
    referentials.map(&:name).to_sentence
  end

  def contains_urgent_offer?
    referentials.any?(&:contains_urgent_offer?)
  end

  def publish
    workgroup.publication_setups.enabled.each do |publication_setup|
      publication_setup.publish self
    end
  end

  def clean_previous_operations
    while clean_scope.successful.count > [self.class.keep_operations, 0].max do
      clean_scope.order("created_at asc").first.tap { |m| m.new&.destroy ; m.destroy }
    end
  end

  def has_at_least_one_referential
    unless referentials.length > 0
      errors.add(:base, :no_referential)
    end
  end

  def clean_scope
    parent&.send(self.class.name.tableize)
  end

  def check_other_operations
    if clean_scope && clean_scope.where(status: [:new, :pending, :running]).exists?
      Rails.logger.warn "#{self.class.name} ##{self.id} - Pending #{self.class.name}(s) on #{parent.class.name} #{parent.name}/#{parent.id}"
      errors.add(:base, :multiple_process)
    end
  end

  def after_save_current
  end

  def save_current
    profile_tag :save_current do
      output.update current: new, new: nil
      output.current.update referential_suite: output, ready: true
      new.rebuild_cross_referential_index!

      begin
        after_save_current
      rescue
        output.update current: previous_current, new: new
        raise
      end

      clean_previous_operations
      update status: :successful, ended_at: Time.now
    end
  end

  def create_compliance_check_set(context, control_set, referential)
    ComplianceControlSetCopier.new.copy control_set.id, referential.id, nil, self.class.name, id, context
  end

  def worker_class_name
    "#{self.class.name}Worker"
  end

  def worker_class
    worker_class_name.constantize
  end

  def operation_scheduled?
    queue = Sidekiq::Queue[worker_class.sidekiq_options["queue"]]
    queue.any? { |item| item["class"] == worker_class_name && item.args == [self.id] }
  end

  def child_change
    Rails.logger.debug "#{self.class.name} #{self.inspect} child_change"
    # Wait next child change if one of the check isn't finished
    return if compliance_check_sets.unfinished.exists?

    if compliance_check_sets.all? { |c| c.status.in? %w{successful warning} }
      if new
        # We are done
        save_current
      else
        # We just passed 'before' validations
        if operation_scheduled?
          Rails.logger.warn "#{self.class.name} ##{self.id} - Trying to schedule a #{self.class.name} while it is already enqueued"
        else
          worker_class.perform_async(id)
        end
      end
    else
      referentials.each &:active!
      update status: :failed, ended_at: Time.now
    end
  end

  def compliance_check_set(key, referential = nil)
    referential ||= new
    control = parent.compliance_control_set(key)
    compliance_check_sets.where(compliance_control_set_id: control.id).find_by(referential_id: referential.id, context: key) if control
  end

  def failed!
    update_columns status: :failed, ended_at: Time.now
    new&.failed!
    referentials.each &:active!
  end

  def successful?
    status.to_s == "successful"
  end

  def current?
    output.current == new
  end
end
