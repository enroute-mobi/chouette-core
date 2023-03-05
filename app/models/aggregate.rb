class Aggregate < ApplicationModel
  DEFAULT_KEEP_AGGREGATES = 10

  include OperationSupport
  include NotifiableSupport

  include Measurable

  belongs_to :workgroup
  has_many :compliance_check_sets, -> { where(parent_type: "Aggregate") }, foreign_key: :parent_id, dependent: :destroy
  has_many :resources, class_name: 'Aggregate::Resource'

  validates :workgroup, presence: true

  delegate :output, to: :workgroup

  def parent
    workgroup
  end

  def rollback!
    raise "You cannot rollback to the current version" if current?
    workgroup.output.update current: self.new
    following_aggregates.each(&:cancel!)
    publish rollback: true
    workgroup.aggregated!
  end

  def cancel!
    update status: :canceled
    new&.rollbacked!
  end

  def following_aggregates
    following_referentials = workgroup.output.referentials.where('created_at > ?', new.created_at)
    workgroup.aggregates.where(new_id: following_referentials.pluck(:id))
  end

  def aggregate
    update_column :started_at, Time.now
    update_column :status, :running

    enqueue_job :aggregate!
  end
  alias run aggregate

  # Returns aggregated referentials order by the Workbench priority
  # lower priority first, so higher value first
  def referentials_by_priority
    workgroup.referentials.joins(:workbench).merge(Workbench.order(priority: :desc)).where(id: referentials.map(&:id))
  end

  # Copy the referential provided by a Workbench
  # Clean the pending aggregated dataset (new) if needed
  class WorkbenchCopy
    include Measurable

    def initialize(referential, new)
      @referential, @new = referential, new
    end
    attr_reader :referential, :new

    delegate :workbench, to: :referential
    delegate :priority, to: :workbench

    def overlaps
      ReferentialOverlaps.new referential, new, priority: priority
    end

    def overlapping_periods
      @overlapping_periods ||= overlaps.overlapping_periods
    end

    def aggregate_resource
      @aggregate_resource ||= Aggregate::Resource.new(
        priority: priority,
        workbench_name: workbench.name,
        referential_name: new.name,
        metrics: {
          vehicle_journey_count: new.switch { |n| n.vehicle_journeys.count },
          overlapping_period_count: overlapping_periods.count
        }
      )
    end

    def clean!
      overlapping_periods.each do |overlapping_period|
        Rails.logger.info "Clean Line #{overlapping_period.line_id} on #{overlapping_period.period}"

        clean_scope = Clean::Scope::Line.new(Clean::Scope::Referential.new(new), overlapping_period.line_id)
        clean_period = overlapping_period.period
        [
          Clean::InPeriod.new(clean_scope, clean_period),
          Clean::Metadata::InPeriod.new(clean_scope, clean_period)
        ].each(&:clean!)
      end
    end
    measure :clean!

    def copy!
      duration = ::Benchmark.realtime do
        measure :copy, workbench_id: workbench.id do
          Rails.logger.tagged("Workbench ##{workbench.id}") do
            Rails.logger.info "Aggregate Referential##{referential.id} with priority #{priority}"
            clean!
            ReferentialCopy.new(source: referential, target: new, source_priority: priority).copy!
          end
        end
      end

      aggregate_resource.duration = duration.round

      self
    end

  end

  def aggregate!
    Rails.logger.tagged("Aggregate ##{id}") do
      measure "aggregate", aggregate: id do
        prepare_new

        measure 'referential_copies' do
          referentials_by_priority.each do |source|
            copy = WorkbenchCopy.new(source, new).copy!
            resources << copy.aggregate_resource
          end
        end

        if after_aggregate_compliance_control_set.present?
          create_after_aggregate_compliance_check_set
        else
          save_current
        end
      end
    end
  rescue => e
    Chouette::Safe.capture "Aggregate ##{id} failed", e
    failed!
    raise e if Rails.env.test?
  end

  def workbench_for_notifications
    workgroup.owner_workbench
  end

  def self.keep_operations
    @keep_operations ||= begin
      if Rails.configuration.respond_to?(:keep_aggregates)
        Rails.configuration.keep_aggregates
      else
        DEFAULT_KEEP_AGGREGATES
      end
    end
  end

  def after_save_current
    clean_previous_operations
    publish
    workgroup.aggregated!
  end

  def handle_queue
    concurent_operations.pending.where('created_at < ?', created_at).each(&:cancel!)
    super
  end

  class Resource < ApplicationModel
    self.table_name = 'aggregate_resources'

    belongs_to :aggregate
    acts_as_list scope: :aggregate
  end

  private

  def prepare_new
    Rails.logger.debug "Create a new output"
    # In the unique case, the referential created can't be linked to any workbench
    attributes = {
      organisation: workgroup.owner,
      prefix: "aggregate_#{id}",
      line_referential: workgroup.line_referential,
      stop_area_referential: workgroup.stop_area_referential,
      objectid_format: referentials.first.objectid_format,
      workbench: nil
    }
    new = workgroup.output.referentials.new attributes
    new.referential_suite = output
    new.name = I18n.t("aggregates.referential_name", date: I18n.l(created_at, format: :short_with_time))

    unless new.valid?
      Rails.logger.error "New referential isn't valid : #{new.errors.inspect}"
    end

    begin
      new.save!
    rescue
      Rails.logger.debug "Errors on new referential: #{new.errors.messages}"
      raise
    end

    new.pending!

    output.update new: new
    update new: new
  end
  measure :prepare_new

  def after_aggregate_compliance_control_set
    @after_aggregate_compliance_control_set ||= workgroup.compliance_control_set(:after_aggregate)
  end

  def create_after_aggregate_compliance_check_set
    create_compliance_check_set :after_aggregate, after_aggregate_compliance_control_set, new
  end
end