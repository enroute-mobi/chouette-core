class Workgroup < ApplicationModel
  NIGHTLY_AGGREGATE_CRON_TIME = 5.minutes

  belongs_to :line_referential
  belongs_to :stop_area_referential
  belongs_to :owner, class_name: "Organisation"
  belongs_to :output, class_name: 'ReferentialSuite'

  has_many :workbenches, dependent: :destroy
  has_many :imports, through: :workbenches
  has_many :calendars, dependent: :destroy
  has_many :organisations, through: :workbenches
  has_many :referentials, through: :workbenches
  has_many :aggregates, dependent: :destroy
  has_many :nightly_aggregates
  has_many :publication_setups, dependent: :destroy
  has_many :publication_apis, dependent: :destroy
  has_many :compliance_check_sets, through: :workbenches

  validates_uniqueness_of :name

  validates_presence_of :owner
  validates_presence_of :line_referential
  validates_presence_of :stop_area_referential
  validates_uniqueness_of :stop_area_referential_id
  validates_uniqueness_of :line_referential_id

  validates :output, presence: true
  before_validation :initialize_output

  validates :sentinel_min_hole_size, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many :custom_fields, dependent: :destroy

  accepts_nested_attributes_for :workbenches

  @@workbench_scopes_class = WorkbenchScopes::All
  mattr_accessor :workbench_scopes_class

  def custom_fields_definitions
    Hash[*custom_fields.map{|cf| [cf.code, cf]}.flatten]
  end

  def has_export? export_name
    export_types.include? export_name
  end

  def self.all_compliance_control_sets
    %i(after_import
      after_import_by_workgroup
      before_merge
      before_merge_by_workgroup
      after_merge
      after_merge_by_workgroup
      automatic_by_workgroup
    )
  end

  def self.workgroup_compliance_control_sets
    %i[
      after_aggregate
    ]
  end

  def self.all_compliance_control_sets_labels
    compliance_control_sets_labels all_compliance_control_sets
  end

  def self.compliance_control_sets_for_workgroup
    compliance_control_sets_labels workgroup_compliance_control_sets
  end

  def self.compliance_control_sets_by_workgroup
    compliance_control_sets_labels all_compliance_control_sets.grep(/by_workgroup$/)
  end

  def self.compliance_control_sets_by_workbench
    compliance_control_sets_labels all_compliance_control_sets.grep_v(/by_workgroup$/)
  end

  def self.import_compliance_control_sets
    compliance_control_sets_labels all_compliance_control_sets.grep(/^after_import/)
  end

  def self.before_merge_compliance_control_sets
    compliance_control_sets_labels all_compliance_control_sets.grep(/^before_merge/)
  end

  def self.after_merge_compliance_control_sets
    compliance_control_sets_labels all_compliance_control_sets.grep(/^after_merge/)
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

  def nightly_aggregate_time
    LocalDaytime.new nightly_aggregate_time_before_type_cast
  end

  def nightly_aggregate_time= val
    if val.is_a?(String)
      val = LocalDaytime.convert_to_db val
    end
    super val
  end

  def aggregate_urgent_data!
    target_referentials = aggregatable_referentials.select do |r|
      aggregated_at.blank? || (r.flagged_urgent_at.present? && r.flagged_urgent_at > aggregated_at)
    end

    return if target_referentials.empty?

    aggregates.create!(referentials: aggregatable_referentials, creator: 'webservice', notification_target: nil)
  end

  def nightly_aggregate!
    Rails.logger.info "Workgroup #{id}: nightly_aggregate!"
    return unless nightly_aggregate_timeframe?

    target_referentials = aggregatable_referentials.select do |r|
      aggregated_at.blank? || (r.created_at > aggregated_at)
    end

    if target_referentials.empty?
      Rails.logger.info "No aggregatable referential found for nighlty aggregate on Workgroup #{name} (Id: #{id})"
      return
    end

    nightly_aggregates.create!(referentials: aggregatable_referentials, creator: 'CRON', notification_target: nightly_aggregate_notification_target)
    update(nightly_aggregated_at: Time.current)
  end

  def nightly_aggregate_timeframe?
    return false unless nightly_aggregate_enabled?

    Rails.logger.info "Workgroup #{id}: nightly_aggregate_timeframe!"
    Rails.logger.info "Time.now: #{Time.now.inspect}"
    Rails.logger.info "LocalDaytime.new: #{LocalDaytime.new.inspect}"
    Rails.logger.info "nightly_aggregate_time: #{nightly_aggregate_time.inspect}"
    Rails.logger.info "diff: #{(LocalDaytime.new - nightly_aggregate_time)}"

    cron_delay = NIGHTLY_AGGREGATE_CRON_TIME * 2
    Rails.logger.info "cron_delay: #{cron_delay}"
    within_timeframe = (LocalDaytime.new - nightly_aggregate_time).abs <= cron_delay
    Rails.logger.info "within_timeframe: #{within_timeframe}"

    # "5.minutes * 2" returns a FixNum (in our Rails version)
    within_timeframe && (nightly_aggregated_at.blank? || nightly_aggregated_at < NIGHTLY_AGGREGATE_CRON_TIME.seconds.ago)
  end

  def import_compliance_control_sets
    self.class.import_compliance_control_sets
  end

  def workbench_scopes workbench
    self.class.workbench_scopes_class.new(workbench)
  end

  def all_compliance_control_sets_labels
    self.class.all_compliance_control_sets_labels
  end

  def compliance_control_sets_by_workgroup
    self.class.compliance_control_sets_by_workgroup
  end

  def compliance_control_sets_by_workbench
    self.class.compliance_control_sets_by_workbench
  end

  def before_merge_compliance_control_sets
    self.class.before_merge_compliance_control_sets
  end

  def after_merge_compliance_control_sets
    self.class.after_merge_compliance_control_sets
  end

  def aggregatable_referentials
    workbenches.map { |w| w.referential_to_aggregate }.compact
  end

  def compliance_control_set key
    id = (compliance_control_set_ids || {})[key.to_s]
    ComplianceControlSet.where(id: id).last if id.present?
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

  private
  def clean_transport_modes
    clean = {}
    transport_modes.each do |k, v|
      clean[k] = v.sort.uniq if v.present?
    end
    self.transport_modes = clean
  end

  def self.compliance_control_sets_label(key)
    "workgroups.compliance_control_sets.#{key}".t
  end

  def self.compliance_control_sets_labels(keys)
    keys.inject({}) do |h, k|
      h[k] = compliance_control_sets_label(k)
      h
    end
  end

  def initialize_output
    self.output ||= ReferentialSuite.create
  end

  def self.default_export_types
    %w[Export::Gtfs Export::NetexFull]
  end

  def self.create_with_organisation organisation, params={}
    name = params[:name] || "#{Workgroup.ts} #{organisation.name}"

    Workgroup.transaction do
      workgroup = Workgroup.create!(name: name) do |workgroup|
        workgroup.owner = organisation
        workgroup.export_types = Workgroup.default_export_types

        workgroup.line_referential ||= LineReferential.create!(name: LineReferential.ts) do |referential|
          referential.add_member organisation, owner: true
          referential.objectid_format = :netex
          referential.sync_interval = 1 # XXX is this really useful ?
        end

        workgroup.stop_area_referential ||= StopAreaReferential.create!(name: StopAreaReferential.ts) do |referential|
          referential.add_member organisation, owner: true
          referential.objectid_format = :netex
        end
      end

      organisation.workbenches.create!(name: Workbench.ts) do |w|
        w.line_referential      = workgroup.line_referential
        w.stop_area_referential = workgroup.stop_area_referential
        w.workgroup             = workgroup
        w.objectid_format       = 'netex'
        w.prefix = organisation.code
      end

      workgroup
    end
  end
end
