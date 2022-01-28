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

  # Ensure that the perform method is always invoked within around_perform
  # TODO Share this mechanism
  def self.method_added(method_name)
    unless @setting_callback || method_name != :perform
      @setting_callback = true
      original = instance_method :perform
      define_method :protected_perform do |*args, &block|
        around_perform do
          original.bind(self).call(*args, &block)
        end
      end
      alias_method :perform, :protected_perform
      @setting_callback = false
    end

    super method_name
  end

  protected

  def around_perform(&block)
    CustomFieldsSupport.within_workgroup(workgroup) do
      logger.tagged operation_description do
        uuid = nil
        begin
          if status.in?([Operation.status.running, Operation.status.done])
            logger.warn "Skip operation since status is already #{status}"
            return
          end

          Chouette::Benchmark.measure(self.class.to_s, id: id) do
            change_status Operation.status.running, started_at: Time.zone.now
            block.call
          end
        rescue => e
          self.error_uuid = uuid = Chouette::Safe.capture("Operation #{operation_description} failed", e)
        end

        change_status Operation.status.done, ended_at: Time.zone.now, error_uuid: uuid
      end
    end
  end

  def change_status(status, attributes = {})
    attributes.delete_if { |_,v| v.nil? }
    # TODO the operation description is already present when logger is tagged during around_perform
    status_log_message = "[#{operation_description}] Status: #{status}"
    status_log_message += " #{attributes.inspect}" unless attributes.empty?
    logger.info status_log_message

    attributes = attributes.merge(status: status) if status
    if persisted?
      update_columns attributes
    else
      self.attributes = attributes
    end
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
