# frozen_string_literal: true

module OperationSupport
  extend ActiveSupport::Concern

  included do |into|
    into.extend Enumerize

    enumerize :status, in: %w[new pending successful failed running canceled], default: :new
    scope :successful, ->{ where status: :successful }
    scope :for_referential, ->(referential){ where('referential_ids @> ARRAY[?]::bigint[]', referential.id) }
    scope :pending, ->{ where status: :pending }
    scope :running, ->{ where status: :running }

    has_array_of :referentials, class_name: '::Referential'
    belongs_to :new, class_name: '::Referential'
    has_many :publications, as: :parent, dependent: :destroy

    validates :creator, presence: true
    validate :has_at_least_one_referential, :on => :create
    validate :check_other_operations, :on => :create

    attr_accessor :automatic_operation

    after_commit :handle_queue, on: :create, if: :automatic_operation?
    after_commit :run, on: :create, if: :manual_operation?

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

  def manual_operation?
    !automatic_operation?
  end

  def automatic_operation?
    automatic_operation
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

  def publish(options = {})
    workgroup.publication_setups.enabled.each do |publication_setup|
      publication = publication_setup.publish(self, options)
      publication.enqueue
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

  def parent_operations
    if parent
      parent.send(self.class.name.tableize)
    else
      self.class.none
    end
  end

  def clean_scope
    parent_operations
  end

  def concurent_operations
    clean_scope ? clean_scope.where.not(id: self.id) : self.class.none
  end

  def check_other_operations
    return if automatic_operation?

    if concurent_operations.where(status: [:new, :pending, :running]).exists?
      Rails.logger.warn "#{self.class.name} ##{self.id} - Pending #{self.class.name}(s) on #{parent.class.name} #{parent.name}/#{parent.id}"
      errors.add(:base, :multiple_process)
    end
  end

  def handle_queue
    if concurent_operations.where(status: [:new, :pending, :running]).exists?
      Rails.logger.warn "#{self.class.name} ##{self.id} - Pending #{self.class.name}(s) on #{parent.class.name} #{parent.name}/#{parent.id}"
      pending!
    else
      run
    end
  end

  def run_pending_operations
    return if concurent_operations.running.exists?

    concurent_operations.order(:created_at).pending.first&.run
  end

  def after_save_current
  end

  def save_current
    Chouette::Benchmark.measure("save_current") do
      output.update current: new, new: nil
      output.current.update referential_suite: output, ready: true
      new.rebuild_cross_referential_index!

      previous_current = output.current
      begin
        after_save_current
      rescue
        output.update current: previous_current, new: new
        raise
      end

      clean_previous_operations
      run_pending_operations
      update status: :successful, ended_at: Time.now
    end
  end

  def operation_scheduled?
    Delayed::Job.where("handler ILIKE '%#{self.class.name}%name: id\n    value_before_type_cast: #{self.id}%'").exists?
  end

  def enqueue_operation
    worker_method = "#{self.class.name.underscore}!".to_sym
    enqueue_job worker_method
  end

  def failed!
    internal_failed
    new&.failed!
  end
  
  # Uses when a Control List Run or Macro List Run report error
  def internal_failed
    update_columns status: :failed, ended_at: Time.now

    workbench = try(:workbench) || try(:workbench_for_notifications)
    workbench&.notification_center&.notify(self)

    referentials.each(&:active!)
    run_pending_operations
  end
  alias failed_on_processings internal_failed

  def worker_died
    failed!

    Rails.logger.error "#{self.class.name} #{self.inspect} failed due to worker being dead"
  end

  def pending!
    update_columns status: :pending
  end

  def cancel!
    update_columns status: :canceled
    run_pending_operations
  end

  %w[new pending successful failed running canceled].each do |s|
    define_method "#{s}?" do
      status.to_s == s
    end
  end

  def current?
    output.current == new
  end
end
