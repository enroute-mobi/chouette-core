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
  has_many :aggregate_schedulings, dependent: :destroy
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
  accepts_nested_attributes_for :aggregate_schedulings, allow_destroy: true, reject_if: :all_blank

  @@workbench_scopes_class = WorkbenchScopes::All
  mattr_accessor :workbench_scopes_class

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

  def aggregate!(**options)
    Aggregator.new(self, **options).run
  end

  def aggregate_urgent_data!
    UrgentAggregator.new(self).run
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
      options[:daily_publications] != false
    end

    def last_successful_aggregate
      @last_successful_aggregate ||= workgroup.aggregates.successful.last
    end

    def log?
      options[:log] != false
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

    def aggregate_attributes
      options[:aggregate_attributes] || {}
    end

    private

    def aggregate!
      log('Start Aggregate')
      workgroup.aggregates.create!(
        referentials: aggregatable_referentials,
        creator: I18n.t('workgroups.aggregator.creator'),
        notification_target: workgroup.nightly_aggregate_notification_target,
        **aggregate_attributes
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
    def daily_publications?
      false
    end

    def log?
      false
    end

    protected

    def select_target_referential?(referential)
      referential.flagged_urgent_at && referential.flagged_urgent_at > workgroup.aggregated_at
    end

    def aggregate_attributes
      { notification_target: 'none', automatic_operation: true }
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

  def create_dependencies
    self.output ||= ReferentialSuite.create
    self.shape_referential ||= ShapeReferential.create
    create_fare_referenial
  end

  def create_fare_referenial
    self.fare_referential ||= Fare::Referential.create
  end

end
