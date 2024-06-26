class Workgroup < ApplicationModel
  DEFAULT_EXPORT_TYPES = %w[Export::Gtfs Export::NetexGeneric Export::Ara].freeze

  belongs_to :line_referential, dependent: :destroy, required: true
  belongs_to :stop_area_referential, dependent: :destroy, required: true
  belongs_to :shape_referential, dependent: :destroy, required: true
  belongs_to :fare_referential, dependent: :destroy, required: true, class_name: 'Fare::Referential'

  # Ensure StopAreaReferential and LineReferential (and their contents)
  # are destroyed before other relations
  before_destroy(prepend: true)  do |workgroup|
    workgroup.stop_area_referential&.destroy!
    workgroup.line_referential&.destroy!
  end

  belongs_to :owner, class_name: "Organisation", required: true
  belongs_to :output, class_name: 'ReferentialSuite', dependent: :destroy, required: true

  has_many :workbenches, dependent: :destroy
  has_many :document_types, dependent: :destroy
  has_many :documents, through: :workbenches
  has_many :document_providers, through: :workbenches
  has_many :document_memberships, through: :documents, source: :memberships
  has_many :imports, through: :workbenches
  has_many :exports, class_name: 'Export::Base', dependent: :destroy
  has_many :calendars, through: :workbenches
  has_many :organisations, through: :workbenches
  has_many :referentials, through: :workbenches
  has_many :aggregates, dependent: :destroy
  has_many :publication_setups, dependent: :destroy
  has_many :publication_apis, dependent: :destroy
  has_many :macro_lists, through: :workbenches
  has_many :macro_list_runs, through: :workbenches
  has_many :control_lists, through: :workbenches
  has_many :control_list_runs, through: :workbenches
  has_many :processing_rules, class_name: "ProcessingRule::Workgroup"
  has_many :workbench_processing_rules, through: :workbenches, source: :processing_rules
  has_many :contracts, through: :workbenches
  has_many :saved_searches, class_name: 'Search::Save', as: :parent, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates_uniqueness_of :stop_area_referential_id
  validates_uniqueness_of :line_referential_id
  validates_uniqueness_of :shape_referential_id
  validates_uniqueness_of :fare_referential_id

  validates :output, presence: true
  before_validation :create_dependencies, on: :create

  has_many :custom_fields, dependent: :delete_all, inverse_of: :workgroup
  has_many :custom_field_groups, inverse_of: :workgroup

  has_many :code_spaces, dependent: :destroy do
    def default
      find_or_create_by(short_name: CodeSpace::DEFAULT_SHORT_NAME)
    end
    def public
      find_or_create_by(short_name: CodeSpace::PUBLIC_SHORT_NAME)
    end
  end
  has_many :codes, through: :code_spaces

  accepts_nested_attributes_for :workbenches

  @@workbench_scopes_class = WorkbenchScopes::All
  mattr_accessor :workbench_scopes_class

  attribute :nightly_aggregate_days, WeekDays.new

  def reverse_geocode
    @reverse_geocode ||= ReverseGeocode::Config.new do |config|
      if owner.has_feature?("reverse_geocode")
        config.resolver_classes << ReverseGeocode::Resolver::TomTom
        config.resolver_classes << ReverseGeocode::Resolver::Cache
      end
    end
  end

  def custom_fields_definitions
    Hash[*custom_fields.map{|cf| [cf.code, cf]}.flatten]
  end

  def has_export? export_name
    export_types.include? export_name
  end

  def self.purge_all
    Workgroup.where.not(deleted_at: nil).each do |workgroup|
      Rails.logger.info "Destroy Workgroup #{workgroup.name} from #{workgroup.owner.name}"
      workgroup.destroy
    end
  end

  def aggregated!
    update aggregated_at: Time.now
  end

  attribute :nightly_aggregate_time, TimeOfDay::Type::TimeWithoutZone.new

  def aggregate!(**options)
    Aggregator.new(self, **options).run
  end

  def aggregate_urgent_data!
    UrgentAggregator.new(
      self,
      aggregate_attributes: { creator: 'webservice', automatic_operation: true }
    ).run
  end

  class Aggregator
    def initialize(workgroup, **options)
      @workgroup = workgroup
      @options = options
    end
    attr_reader :workgroup, :options

    def run
      if aggregate?
        aggregate!
      elsif daily_publications?
        daily_publish!
      end
    end

    def aggregatable_referentials
      @aggregatable_referentials ||= workgroup.aggregatable_referentials
    end

    def target_referentials
      @target_referentials ||= if workgroup.aggregated_at
                                 aggregatable_referentials.select { |r| select_target_referential?(r) }
                               else
                                 aggregatable_referentials
                               end
    end

    def aggregate?
      target_referentials.any?
    end

    def daily_publications?
      options[:daily_publications]
    end

    def last_successful_aggregate
      @last_successful_aggregate ||= workgroup.aggregates.successful.last
    end

    def log?
      options[:log]
    end

    def log(msg, debug: false)
      return unless log?

      full_msg = "[Workgroup ##{workgroup.id}] #{msg}"
      if debug
        Rails.logger.debug(full_msg)
      else
        Rails.logger.info(full_msg)
      end
    end

    protected

    def select_target_referential?(referential)
      referential.created_at > workgroup.aggregated_at
    end

    private

    def aggregate!
      log('Start Aggregate')
      workgroup.aggregates.create!(
        referentials: aggregatable_referentials,
        creator: 'creator',
        **(options[:aggregate_attributes] || {})
      )
    end

    def daily_publish!
      log('No Aggregate is required')
      return unless last_successful_aggregate

      workgroup.publication_setups.where(force_daily_publishing: true).find_each do |publication_setup|
        log("Start daily publication #{publication_setup.name}")
        last_successful_aggregate.publish_with_setup(publication_setup)
      end
    end
  end

  class UrgentAggregator < Aggregator
    protected

    def select_target_referential?(referential)
      referential.flagged_urgent_at && referential.flagged_urgent_at > workgroup.aggregated_at
    end
  end

  concerning :AggregateScheduling do # rubocop:disable Metrics/BlockLength
    included do
      belongs_to :scheduled_aggregate_job, class_name: '::Delayed::Job', optional: true

      after_commit :reschedule_aggregate, on: %i[create update], if: :reschedule_aggregate_needed?
      after_commit :destroy_scheduled_aggregate_job, on: :destroy
    end

    def aggregate_schedule_enabled?
      nightly_aggregate_enabled && !nightly_aggregate_days.none? # rubocop:disable Style/InverseMethods
    end

    def next_aggregate_schedule
      return unless aggregate_schedule_enabled?

      scheduled_aggregate_job&.run_at
    end

    def reschedule_aggregate # rubocop:disable Metrics/MethodLength
      if aggregate_schedule_enabled?
        job = Workgroup::ScheduledAggregateJob.new(self)

        if scheduled_aggregate_job
          scheduled_aggregate_job.update(cron: job.cron)
        else
          delayed_job = Delayed::Job.enqueue(job, cron: job.cron)
          update_column(:scheduled_aggregate_job_id, delayed_job.id) # rubocop:disable Rails/SkipsModelValidations
        end
      else
        update_column(:scheduled_aggregate_job_id, nil) # rubocop:disable Rails/SkipsModelValidations
        destroy_scheduled_aggregate_job
      end
    end

    private

    def reschedule_aggregate_needed?
      saved_change_to_nightly_aggregate_enabled || \
        saved_change_to_nightly_aggregate_time || \
        saved_change_to_nightly_aggregate_days
    end

    def destroy_scheduled_aggregate_job
      scheduled_aggregate_job&.destroy
    end
  end

  class ScheduledAggregateJob
    def initialize(workgroup)
      @workgroup = workgroup
    end
    attr_reader :workgroup

    def encode_with(coder)
      coder['workgroup_id'] = workgroup.id
    end

    def init_with(coder)
      @workgroup = Workgroup.find(coder['workgroup_id'])
    end

    def cron
      [
        workgroup.nightly_aggregate_time.minute,
        workgroup.nightly_aggregate_time.hour,
        '*',
        '*',
        workgroup.nightly_aggregate_days.to_cron
      ].join(' ')
    end

    def perform
      return unless workgroup.aggregate_schedule_enabled?

      workgroup.aggregate!(
        creator: 'CRON',
        aggregate_attributes: { notification_target: workgroup.nightly_aggregate_notification_target },
        daily_publications: true,
        log: true
      )
    rescue StandardError => e
      Chouette::Safe.capture "Can't start Workgroup##{workgroup.id}::ScheduledAggregateJob", e
    end
  end

  def workbench_scopes workbench
    self.class.workbench_scopes_class.new(workbench)
  end

  def aggregatable_referentials
    workbenches.map { |w| w.referential_to_aggregate }.compact
  end

  def owner_workbench
    workbenches.find_by organisation_id: owner_id
  end

  def setup_deletion!
    update_attribute :deleted_at, Time.now
  end

  def remove_deletion!
    update_attribute :deleted_at, nil
  end

  def transport_modes_as_json
    transport_modes.to_json
  end

  def transport_modes_as_json=(json)
    self.transport_modes = JSON.parse(json)
    clean_transport_modes
  end

  def sorted_transport_modes
    transport_modes.keys.sort_by{|k| "enumerize.transport_mode.#{k}".t}
  end

  def sorted_transport_submodes
    transport_modes.values.flatten.uniq.sort_by{|k| "enumerize.transport_submode.#{k}".t}
  end

  def formatted_submodes_for_transports
    TransportModeEnumerations.formatted_submodes_for_transports(transport_modes)
  end

  DEFAULT_TRANSPORT_MODE = "bus"

  # Returns [ "bus", "undefined" ] when the Workgroup accepts this transport mode.
  # else returns first transport mode with its first submode
  def default_transport_mode
    transport_mode =
      if transport_modes.keys.include?(DEFAULT_TRANSPORT_MODE)
        DEFAULT_TRANSPORT_MODE
      else
        sorted_transport_modes.first
      end

    transport_submode =
      if transport_modes[transport_mode].include?("undefined")
        "undefined"
      else
        transport_modes[transport_mode].first
      end

    [ transport_mode, transport_submode ]
  end

  def route_planner
    @route_planner ||= RoutePlanner::Config.new do |config|
      if owner.has_feature?('route_planner')
        config.resolver_classes << RoutePlanner::Resolver::TomTom
        config.resolver_classes << RoutePlanner::Resolver::Cache
      end
    end
  end

  def self.create_with_organisation organisation, params={}
    name = params[:name] || organisation.name

    Workgroup.transaction do
      workgroup = Workgroup.create!(name: name) do |workgroup|
        workgroup.owner = organisation
        workgroup.export_types = DEFAULT_EXPORT_TYPES

        workgroup.line_referential ||= LineReferential.create!(name: LineReferential.ts) do |referential|
          referential.add_member organisation, owner: true
          referential.objectid_format = :netex
        end

        workgroup.stop_area_referential ||= StopAreaReferential.create!(name: StopAreaReferential.ts) do |referential|
          referential.add_member organisation, owner: true
          referential.objectid_format = :netex
        end
      end

      workgroup.workbenches.create!(name: name, organisation: organisation)

      workgroup
    end
  end

  private
  def clean_transport_modes
    clean = {}
    transport_modes.each do |k, v|
      clean[k] = v.sort.uniq if v.present?
    end
    self.transport_modes = clean
  end

  def create_dependencies
    self.output ||= ReferentialSuite.create
    self.shape_referential ||= ShapeReferential.create
    create_fare_referenial
  end

  def create_fare_referenial
    self.fare_referential ||= Fare::Referential.create
  end

end
