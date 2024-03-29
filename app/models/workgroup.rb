class Workgroup < ApplicationModel
  NIGHTLY_AGGREGATE_CRON_TIME = 5.minutes
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

  def aggregate_urgent_data!
    target_referentials = aggregatable_referentials.select do |r|
      aggregated_at.blank? || (r.flagged_urgent_at.present? && r.flagged_urgent_at > aggregated_at)
    end

    return if target_referentials.empty?

    aggregates.create!(referentials: aggregatable_referentials, creator: 'webservice', notification_target: nil, automatic_operation: true)
  end

  def nightly_aggregate!
    Rails.logger.debug "[Workgroup ##{id}]: Test nightly aggregate time frame"
    return unless nightly_aggregate_timeframe?

    Rails.logger.info "[Workgroup ##{id}] Check nightly Aggregate (at #{nightly_aggregate_time})"

    update_column :nightly_aggregated_at, Time.current

    target_referentials = aggregatable_referentials.select do |r|
      aggregated_at.blank? || (r.created_at > aggregated_at)
    end

    if target_referentials.empty?
      Rails.logger.info "[Workgroup ##{id}] No Aggregate is required"

      aggregate = aggregates.where(status: 'successful').last

      if aggregate
        publication_setups.where(force_daily_publishing: true).each do |ps|
          Rails.logger.info "[Workgroup ##{id}] Start daily publication #{name}"
          ps.publish(aggregate) if aggregate
        end
      end

      return
    end

    Rails.logger.info "[Workgroup ##{id}] Start nightly Aggregate"

    aggregates.create!(referentials: aggregatable_referentials, creator: 'CRON', notification_target: nightly_aggregate_notification_target)

  end

  def nightly_aggregate_timeframe?
    return false unless nightly_aggregate_enabled?

    Rails.logger.debug "Workgroup #{id}: nightly_aggregate_timeframe!"
    Rails.logger.debug "Time.now: #{Time.now.inspect}"
    Rails.logger.debug "TimeOfDay.now: #{TimeOfDay.now.inspect}"
    Rails.logger.debug "nightly_aggregate_time: #{nightly_aggregate_time.inspect}"
    Rails.logger.debug "diff: #{(TimeOfDay.now - nightly_aggregate_time)}"

    within_timeframe = (TimeOfDay.now - nightly_aggregate_time).abs <= NIGHTLY_AGGREGATE_CRON_TIME && nightly_aggregate_days.match_date?(Time.zone.now)
    Rails.logger.debug "within_timeframe: #{within_timeframe}"

    cool_down_time = (NIGHTLY_AGGREGATE_CRON_TIME*3).ago
    within_timeframe && (nightly_aggregated_at.blank? || nightly_aggregated_at < cool_down_time)
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
