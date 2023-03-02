module LockedReferentialToAggregateWithLog
  def locked_referential_to_aggregate
    super.tap do |ref|
      if locked_referential_to_aggregate_id.present? && !ref.present?
        Rails.logger.warn "Locked Referential for Workbench##{id} has been deleted"
      end
    end
  end
end

class Workbench < ApplicationModel
  prepend LockedReferentialToAggregateWithLog

  include ObjectidFormatterSupport

  belongs_to :organisation, optional: true
  belongs_to :workgroup
  belongs_to :line_referential
  belongs_to :stop_area_referential
  has_one :shape_referential, through: :workgroup
  belongs_to :output, class_name: 'ReferentialSuite', dependent: :destroy
  belongs_to :locked_referential_to_aggregate, class_name: 'Referential'

  has_many :users, through: :organisation
  has_many :lines, -> (workbench) { workbench.workbench_scopes.lines_scope(self) }, through: :line_referential
  has_many :stop_areas, -> (workbench) { workbench.workbench_scopes.stop_areas_scope(self) }, through: :stop_area_referential
  has_many :networks, through: :line_referential
  has_many :companies, through: :line_referential
  has_many :line_notices, through: :line_referential
  has_many :group_of_lines, through: :line_referential
  has_many :imports, class_name: 'Import::Base', dependent: :destroy
  has_many :exports, class_name: 'Export::Base', dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :workbench_imports, class_name: 'Import::Workbench', dependent: :destroy
  has_many :compliance_check_sets, dependent: :destroy
  has_many :merges, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :source_retrievals, class_name: "Source::Retrieval"
  has_many :processing_rules, class_name: "ProcessingRule::Workbench"

  validates :name, presence: true
  validates :organisation, presence: true, unless: :pending?
  validates :prefix, presence: true, unless: :pending?
  validates_format_of :prefix, with: %r{\A[0-9a-zA-Z_]+\Z}, unless: :pending?
  validates :invitation_code, presence: true, uniqueness: true, if: :pending?

  validates :output, presence: true
  validate  :locked_referential_to_aggregate_belongs_to_output

  has_many :referentials, dependent: :destroy
  has_many :referential_metadatas, through: :referentials, source: :metadatas
  has_many :notification_rules, dependent: :destroy

  has_many :shape_providers, dependent: :destroy
  has_many :line_providers, dependent: :destroy
  has_many :stop_area_providers, dependent: :destroy
  has_many :fare_providers, dependent: :destroy, class_name: 'Fare::Provider'

  has_many :macro_lists, class_name: "Macro::List", dependent: :destroy
  has_many :macro_list_runs, class_name: "Macro::List::Run", dependent: :destroy

  has_many :control_lists, class_name: "Control::List", dependent: :destroy
  has_many :control_list_runs, class_name: "Control::List::Run", dependent: :destroy

  has_many :document_providers
  has_many :documents, through: :document_providers

  before_validation :create_dependencies, on: :create
  before_validation :create_default_prefix

  validates :priority, presence: true, numericality: { greater_than_or_equal_to: 1 }

  scope :with_active_workgroup, -> { joins(:workgroup).where('workgroups.deleted_at': nil) }

  def pending?
    organisation_id.blank?
  end

  def control_lists_shared_with_workgroup
    workgroup.control_lists.where("shared = ? OR workbench_id = ?", true, self).distinct
  end

  def locked_referential_to_aggregate_belongs_to_output
    return unless locked_referential_to_aggregate.present?
    return if locked_referential_to_aggregate.referential_suite == output

    errors.add(
      :locked_referential_to_aggregate,
      I18n.t('workbenches.errors.locked_referential_to_aggregate.must_belong_to_output')
    )
  end

  def workbench_scopes
    workgroup.workbench_scopes(self)
  end

  def all_referentials
    if line_ids.empty?
      Referential.none
    else
      Referential.where(id: workgroup
        .referentials
        .joins(:metadatas)
        .where(['referential_metadata.line_ids && ARRAY[?]::bigint[]', line_ids])
        .not_in_referential_suite.pluck(:id).uniq
      )

    end
  end

  def notifications_channel
    "/workbenches/#{id}"
  end

  def notification_center
    @notification_center ||= NotificationCenter.new(self)
  end

  def referential_to_aggregate
    locked_referential_to_aggregate || output. current
  end

  def calendars
    workgroup.calendars.where('(organisation_id = ? OR shared = ?)', organisation.id, true)
  end

  def compliance_control_set key
    id = (owner_compliance_control_set_ids || {})[key.to_s]
    ComplianceControlSet.where(id: id).last if id.present?
  end

  def compliance_control_set_ids=(compliance_control_set_ids)
    self.owner_compliance_control_set_ids = (owner_compliance_control_set_ids || {}).merge compliance_control_set_ids
  end

  def has_restriction?(restriction)
    restrictions && restrictions.include?(restriction.to_s)
  end

  def self.available_restriction
    ["referentials.flag_urgent"]
  end

  def last_merged_data
    merges.select(&:successful?).map(&:updated_at).max
  end

  DEFAULT_PROVIDER_NAME = 'default'
  DEFAULT_PROVIDER_SHORT_NAME = 'default'

  def default_shape_provider
    # The find_or_initialize_by results in self.shape_providers.build, that new related object instance is saved when self is saved
    @default_shape_provider ||= shape_providers.find_or_initialize_by(short_name: DEFAULT_PROVIDER_SHORT_NAME) do |p|
      p.shape_referential_id = workgroup.shape_referential_id
    end
  end

  def default_fare_provider
    @default_fare_provider ||= fare_providers.find_or_initialize_by(short_name: DEFAULT_PROVIDER_SHORT_NAME) do |p|
      p.fare_referential_id = workgroup.fare_referential_id
    end
  end

  def create_default_fare_provider
    default_fare_provider.save
  end

  def default_line_provider
    @default_line_provider ||= line_providers.first || create_default_line_provider
  end

  def create_default_line_provider
    line_providers.find_or_initialize_by(name: DEFAULT_PROVIDER_NAME) do |p|
      p.line_referential_id = workgroup.line_referential_id
      p.short_name = DEFAULT_PROVIDER_SHORT_NAME
      p.save
    end
  end

  mattr_accessor :disable_default_stop_area_provider

  def default_stop_area_provider
    @default_stop_area_provider ||= stop_area_providers.first || create_default_stop_area_provider
  end

  def default_document_provider
    @default_document_provider ||= document_providers.find_or_initialize_by(name: DEFAULT_PROVIDER_SHORT_NAME)
  end

  def create_default_stop_area_provider
    return if disable_default_stop_area_provider
    stop_area_providers.find_or_initialize_by(name: DEFAULT_PROVIDER_SHORT_NAME.capitalize) do |p|
      p.stop_area_referential_id = stop_area_referential_id
    end
  end

  def create_default_shape_provider
    default_shape_provider.save
  end

  def create_invitation_code
    self.invitation_code	||= 3.times.map { "%03d" % SecureRandom.random_number(1000) }.join('-')
  end

  class Confirmation
    include ActiveModel::Model

    def self.policy_class
      WorkbenchConfirmationPolicy
    end

    attr_accessor :organisation, :invitation_code

    CODE_FORMAT = /\A\d{3}-\d{3}-\d{3}\z/

    validates :organisation, :invitation_code, presence: true
    validates :invitation_code, format: { with: CODE_FORMAT }

    validate :workbench_exists

    def workbench
      @workbench ||= Workbench.where(invitation_code: invitation_code).where.not(workgroup: existing_workgroups).first
    end

    def existing_workgroups
      if organisation
        organisation.workgroups
      else
        Workgroup.none
      end
    end

    def workbench_exists
      unless workbench
        errors.add :invitation_code, :invalid
      end
    end

    def save
      return false unless valid?
      workbench.update organisation: organisation, invitation_code: nil
    end

    def save!
      save || raise(ActiveRecord::RecordNotSaved.new("Failed to save the record", self))
    end
  end

  def create_default_prefix
    if code = organisation&.code
      self.prefix ||= code.gsub("-","_").parameterize(separator: "_")
    end
  end

  def create_default_document_provider
    default_document_provider.save
  end

  private

  def create_dependencies
    self.output ||= ReferentialSuite.create

    if pending?
      create_invitation_code
    end

    if workgroup
			self.line_referential      ||= workgroup.line_referential
      self.stop_area_referential ||= workgroup.stop_area_referential
      self.objectid_format       ||= 'netex'

      default_shape_provider
      default_line_provider
      default_stop_area_provider
      
      create_default_fare_provider
      create_default_document_provider
    end
  end
end
