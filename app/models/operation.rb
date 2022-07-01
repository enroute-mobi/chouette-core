# == Start an Operation
#
#   operation = build_method(user: current_user)
#   if operation.save
#      operation.enqueue
#   else
#      # ...
#   end
#
# == Live Cycle
#
#   operation = <RealOperationClass>.new(user: current_user)
#   operation.status => 'new'
#   operation.creator => "Current User Name"
#
#   operation.perform
#
#   # during perform
#   operation.status => 'running'
#   operation.started_at => <1s ago

#   # when perform is finished
#   operation.status => 'done'
#   operation.ended_at => <1s ago>
#
# If an Ruby error occurs during perform:
#
#   operation.perform
#   operation.status => 'done'
#   operation.error_uuid => '6a651109-ac36-409d-8f1f-d95c78b46eb3'
#
# To perform the (persisted) Operation with a Job:
#
#   operation.save! # the Operation must be persisted before enqueuing it
#   operation.enqueue
#   operation.status => 'enqueued'
#
# == Implement a new Operation
#
#   class Dummy < Operation
#
#     def perform
#        logger.info "Just do it !"
#     end
#
#   end
#
# == User Status
#
#   operation.user_status => <#UserStatus slug='pending'>
#   operation.perform => <#UserStatus slug='successful'>
#
# == Log
#
# All log messages during the perform method are tagged:
#
#   [Macro::List::Run(id=4)] Status: enqueued
#   [Macro::List::Run(id=4)] [Macro::List::Run(id=4)] Status: running {:started_at=>Fri, 17 Dec 2021 11:38:40 CET +01:00}
#   [Macro::List::Run(id=4)]   Macro::List::Run Update (0.1ms)  UPDATE ...
#   [Macro::List::Run(id=4)]   Macro::Base::Run Load (0.2ms)  SELECT ...
#   [Macro::List::Run(id=4)] [ERROR] Operation Macro::List::Run(id=4) failed (6a651109-ac36-409d-8f1f-d95c78b46eb3): RuntimeError Raise error as expected /home/alban/Projects/chouette-core/app/models/macro/dummy.rb:8:in `run'
#   [Macro::List::Run(id=4)] [Macro::List::Run(id=4)] Status: done {:ended_at=>Fri, 17 Dec 2021 11:38:40 CET +01:00, :error_uuid=>"6a651109-ac36-409d-8f1f-d95c78b46eb3"}
#
# == Benchmark
#
# The perform method enables Chouette::Benchmark measure.
#

class Operation  < ApplicationModel
  self.abstract_class = true

  extend Enumerize

  enumerize :status, in: %w{new enqueued running done}, default: "new"

  def user_status
    if Operation.status.done
      error_uuid.present? ? UserStatus.failed : UserStatus.successful
    else
      UserStatus.pending
    end
  end

  validates :creator, presence: true

  def user=(user)
    @user = user
    self.creator = user.name
  end
  attr_reader :user

  def enqueue
    raise "Operation must be persisted before starting its Job" unless persisted?
    raise "Invalid status #{status}" unless status == Operation.status.new

    # We'll certainly need to manage queues
    Delayed::Job.enqueue job
    change_status Operation.status.enqueued
  end

  def job
    # We could use a dedicated subclass for each Operation class (Control::Job, Macro::Job, etc)
    Job.new id, self.class if persisted?
  end

  def operation_description
    "#{self.class.name}(id=#{self.id})"
  end

  def logger
    Rails.logger
  end

  class Callback
    def initialize(operation)
      @operation = operation
    end
    attr_reader :operation

    delegate :logger, to: :operation

    def around(&block)
      result = nil
      if before
        result = yield
        after
      end
      result
    end

    def before
      true
    end

    def after; end

    # Invoke given callbacks before invoking the given block
    class Invoker
      def initialize(callbacks, &block)
        @final_proc = block
        @callbacks = callbacks
      end
      attr_reader :callbacks, :final_proc

      def enumerator
        @enumerator ||= callbacks.each
      end

      def next_callback
        enumerator.next
      end

      def call
        callback = next_callback
        Rails.logger.debug "Invoke Callback #{callback.class}"
        callback.around { self.call }
      rescue StopIteration
        final_proc.call
      end
    end
  end

  class CustomFieldLoader < Callback
    delegate :workgroup, to: :operation
    def around(&block)
      CustomFieldsSupport.within_workgroup(workgroup) do
        yield
      end
    end
  end

  class LogTagger < Callback
    delegate :operation_description, to: :operation
    def around(&block)
      logger.tagged(operation_description) do
        yield
      end
    end
  end

  class PerformedSkipper < Callback
    delegate :status, to: :operation

    def skipped_statuses
      [ Operation.status.running, Operation.status.done ]
    end

    def before
      if status.in?(skipped_statuses)
        logger.warn "Skip operation since status is already #{status}"
        return false
      end

      true
    end
  end

  class Benchmarker < Callback
    delegate :id, to: :operation
    def around(&block)
      Chouette::Benchmark.measure(operation.class.to_s, id: id) do
        yield
      end
    end
  end

  class StatusChanger < Callback
    def now
      Time.zone.now
    end

    delegate :change_status, :error_uuid, to: :operation

    def before
      change_status Operation.status.running
    end

    def after
      change_status Operation.status.done, error_uuid: error_uuid
    end
  end

  def change_status(status, attributes = {})
    attributes.delete_if { |_,v| v.nil? }

    now = Time.zone.now
    case status
    when Operation.status.running
      attributes[:started_at] = now
    when Operation.status.done
      attributes[:ended_at] = now
    end

    status_log_message = ""
    # the operation description is already present when logger is tagged during around_perform
    status_log_message += "[#{operation_description}] " if status == Operation.status.enqueued
    status_log_message += "Status: #{status}"
    status_log_message += " #{attributes.inspect}" unless attributes.empty?

    logger.info status_log_message

    attributes = attributes.merge(status: status)
    if persisted?
      update_columns attributes
    else
      self.attributes = attributes
    end
  end

  protected

  mattr_reader :callback_classes, default: []

  def self.callback(callback_class)
    callback_classes << callback_class
  end

  # Define logics to be performed before and after Operation#perform
  callback LogTagger
  callback CustomFieldLoader
  callback PerformedSkipper
  callback Benchmarker
  callback StatusChanger

  def callbacks
    callback_classes.map { |callback_class| callback_class.new(self) }
  end

  include AroundMethod
  around_method :perform

  def around_perform(&block)
    Callback::Invoker.new(callbacks) do
      begin
        block.call
      rescue => e
        self.error_uuid = Chouette::Safe.capture("Operation #{operation_description} failed", e)
      end
    end.call
  end

  # Store operation id and class name to load and perform it into Delayed worker
  class Job
    def initialize(operation_id, operation_class)
      @operation_id = operation_id
      @operation_class_name = operation_class.to_s
    end

    attr_reader :operation_id, :operation_class_name
    def operation_class
      @operation_class ||= @operation_class_name.constantize
    end

    def operation
      @operation ||= operation_class.find_by(id: operation_id)
    end

    def operation_description
      "#{operation_class_name}(id=#{operation_id})"
    end

    def explain
      operation_description
    end

    def perform
      unless operation
        logger.warn "Can't find operation #{operation_description}"
        return
      end

      operation.perform
    end

    def max_attempts
      1
    end

    def max_run_time
      Delayed::Worker.max_run_time
    end
  end

  class UserStatus
    def initialize(slug, operation_statuses = nil)
      operation_statuses ||= [ slug ]
      @slug, @operation_statuses = slug.to_sym, operation_statuses.map(&:to_sym)

      operation_statuses.freeze
      freeze
    end

    attr_reader :slug, :operation_statuses

    def self.all
      ALL
    end

    alias to_sym slug

    def to_s
      slug.to_s
    end

    def self.find(*slugs)
      slugs = slugs.flatten.map(&:to_sym)
      all.select { |user_status| slugs.include? user_status.slug }
    end

    PENDING = new 'pending', %w[new pending running]
    FAILED = new 'failed', %w[failed aborted canceled]
    WARNING = new 'warning'
    SUCCESSFUL = new 'successful'

    ALL = [ PENDING, SUCCESSFUL, WARNING, FAILED ].freeze

    def self.pending
      PENDING
    end

    def self.successful
      SUCCESSFUL
    end

    def self.failed
      FAILED
    end
  end
end
