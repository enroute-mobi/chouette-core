# frozen_string_literal: true

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
#   operation.status.new? => true
#   operation.creator => "Current User Name"
#
#   operation.perform
#
#   # during perform
#   operation.status.running? => true
#   operation.started_at => <1s ago

#   # when perform is finished
#   operation.status.done? => true
#   operation.ended_at => <1s ago>
#
# If an Ruby error occurs during perform:
#
#   operation.perform
#   operation.status.done? => true
#   operation.error_uuid => '6a651109-ac36-409d-8f1f-d95c78b46eb3'
#
# To perform the (persisted) Operation with a Job:
#
#   operation.save! # the Operation must be persisted before enqueuing it
#   operation.enqueue
#   operation.status.enqueued? => true
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
#   operation.user_status.pending? => true
#   operation.perform
#   operation.user_status.successful? =>  true
#
# If the operation isn't successful:
#
#   operation.user_status.failed?
#   operation.user_status.warning?
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

class Operation < ApplicationModel
  self.abstract_class = true

  extend Enumerize

  enumerize :status, in: %i[new enqueued running done], default: :new, scope: true
  enumerize :user_status, in: %i[pending successful warning failed], default: :pending, scope: true

  validates :creator, presence: true

  def user=(user)
    @user = user
    self.creator = user.name
  end
  attr_reader :user

  class NotPersistedError < StandardError
    def message
      'Operation must be persisted before starting its Job'
    end
  end

  class InvalidStatusError < StandardError
    def initialize(status)
      @status = status
    end

    def message
      "Invalid status #{@status}"
    end
  end

  def enqueue
    raise NotPersistedError unless persisted?
    raise InvalidStatusError, status unless status.new?

    # We'll certainly need to manage queues
    Delayed::Job.enqueue job
    change_status Operation.status.enqueued
  end

  def job
    # We could use a dedicated subclass for each Operation class (Control::Job, Macro::Job, etc)
    Job.new id, self.class if persisted?
  end

  def internal_description
    "#{self.class.name}(id=#{id})"
  end

  def logger
    Rails.logger
  end

  module CallbackSupport
    extend ActiveSupport::Concern

    included do
      mattr_reader :callback_classes, default: []
    end

    module ClassMethods
      def callback(callback_class)
        callback_classes << callback_class
      end
    end

    def callbacks
      callback_classes.map { |callback_class| callback_class.new(self) }
    end
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
        result = block.call
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
        callback.around { call }
      rescue StopIteration
        final_proc.call
      end
    end
  end

  class CustomFieldLoader < Callback
    delegate :workgroup, to: :operation
    def around(&block)
      CustomFieldsSupport.within_workgroup(workgroup, &block)
    end
  end

  class LogTagger < Callback
    delegate :internal_description, to: :operation
    def around(&block)
      logger.tagged(internal_description, &block)
    end
  end

  class PerformedSkipper < Callback
    delegate :status, to: :operation

    def skipped_statuses
      [Operation.status.running, Operation.status.done]
    end

    def before
      if status.in?(skipped_statuses)
        logger.warn "Skip operation since status is already #{status}"
        return false
      end

      true
    end
  end

  class Bullet < Callback
    def around(&block)
      ::Bullet.profile(&block)
    end
  end

  class StackProf < Callback
    def self.enabled?
      ENV['CHOUETTE_PROFILING'] == 'true'
    end

    def target_file
      @target_file ||= "tmp/#{operation.class}-#{Time.now.strftime('%Y%m%d-%H%M%S')}.prof"
    end
    def around(&block)
      if self.class.enabled?
        logger.debug "Profiling available into #{target_file}"
        ::StackProf.run(mode: :cpu, raw: true, out: target_file, &block)
      else
        block.call
      end
    end
  end

  class Benchmarker < Callback
    delegate :id, to: :operation
    def around(&block)
      Chouette::Benchmark.measure(operation.class.to_s, id: id, &block)
    end
  end

  class StatusChanger < Callback
    delegate :change_status, :error_uuid, to: :operation

    def before
      change_status Operation.status.running
    end

    def after
      change_status Operation.status.done, error_uuid: error_uuid
    end
  end

  class Notifier < Callback
    # To support operations without workbench
    def workbench
      operation.try(:workbench)
    end
    delegate :notification_center, to: :workbench, allow_nil: true

    def after
      notification_center&.notify(operation)
    end
  end

  # Reset any Referential switch before/after the operation
  class Referential < Callback
    def before
      ::Referential.reset
    end

    def after
      ::Referential.reset
    end
  end

  # Can be overrided by subclass to customize the User Status according internal information (messages, resources, controls, etc)
  def final_user_status
    Operation.user_status.successful
  end

  def change_status(status, attributes = {})
    attributes.delete_if { |_, v| v.nil? }

    now = Time.zone.now

    attributes[:started_at] = now if status.running?

    if status.done?
      attributes[:ended_at] = now

      user_status =
        if attributes[:error_uuid] || error_uuid
          Operation.user_status.failed
        else
          final_user_status.to_s
        end
      attributes[:user_status] = user_status
    end

    status_log_message = ''
    # the operation description is already present when logger is tagged during around_perform
    status_log_message += "[#{internal_description}] " if status.enqueued?
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

  include CallbackSupport

  # Define logics to be performed before and after Operation#perform
  callback LogTagger
  callback CustomFieldLoader
  callback PerformedSkipper
  callback Bullet if defined?(::Bullet)
  callback Benchmarker
  callback Notifier
  callback Referential
  callback StatusChanger

  include AroundMethod
  around_method :perform

  def around_perform(&block)
    Callback::Invoker.new(callbacks) do
      block.call
    rescue StandardError => e
      self.error_uuid = Chouette::Safe.capture("Operation #{internal_description} failed", e)
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

    def internal_description
      "#{operation_class_name}(id=#{operation_id})"
    end

    def display_name
      internal_description
    end

    def logger
      Rails.logger
    end

    def perform
      unless operation
        logger.warn "Can't find operation #{internal_description}"
        return
      end

      operation.perform
    end

    def max_attempts
      1
    end
  end

  # Deprecated. Use Operation.user_status enumerize logic
  class UserStatus
    def initialize(slug, operation_statuses = nil)
      operation_statuses ||= [slug]
      @slug = slug.to_sym
      @operation_statuses = operation_statuses.map(&:to_sym)

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

    ALL = [PENDING, SUCCESSFUL, WARNING, FAILED].freeze

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
