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
  DEFAULT_WORKBENCH_NAME = "Gestion de l'offre"

  prepend LockedReferentialToAggregateWithLog

  include ObjectidFormatterSupport
  belongs_to :organisation
  belongs_to :line_referential
  belongs_to :stop_area_referential
  belongs_to :output, class_name: 'ReferentialSuite', dependent: :destroy
  belongs_to :workgroup
  belongs_to :locked_referential_to_aggregate, class_name: 'Referential'

  has_many :users, through: :organisation
  has_many :lines, -> (workbench) { workbench.workbench_scopes.lines_scope(self) }, through: :line_referential
  has_many :stop_areas, -> (workbench) { workbench.workbench_scopes.stop_areas_scope(self) }, through: :stop_area_referential
  has_many :networks, through: :line_referential
  has_many :companies, through: :line_referential
  has_many :group_of_lines, through: :line_referential
  has_many :imports, class_name: 'Import::Base', dependent: :destroy
  has_many :exports, class_name: 'Export::Base', dependent: :destroy
  has_many :workbench_imports, class_name: 'Import::Workbench', dependent: :destroy
  has_many :compliance_check_sets, dependent: :destroy
  has_many :merges, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  validates :name, presence: true
  validates :organisation, presence: true
  validates :prefix, presence: true
  validates_format_of :prefix, with: %r{\A[0-9a-zA-Z_]+\Z}
  validates :output, presence: true
  validate  :locked_referential_to_aggregate_belongs_to_output

  has_many :referentials, dependent: :destroy
  has_many :referential_metadatas, through: :referentials, source: :metadatas
  has_many :notification_rules, dependent: :destroy

  before_validation :initialize_output

  scope :with_active_workgroup, -> { joins(:workgroup).where('workgroups.deleted_at': nil) }


  # def notifiable_lines
  #   lines.where(id: NotificationRule.pluck(:line_id))
  # end

  def locked_referential_to_aggregate_belongs_to_output
    return unless locked_referential_to_aggregate.present?
    return if locked_referential_to_aggregate.referential_suite == output

    errors.add(
      :locked_referential_to_aggregate,
      I18n.t('workbenches.errors.locked_referential_to_aggregate.must_belong_to_output')
    )
  end

  def self.normalize_prefix input
    input ||= ""
    input.to_s.strip.gsub(/[^0-9a-zA-Z_]/, '_')
  end

  def prefix= val
    self[:prefix] = Workbench.normalize_prefix(val)
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

  def referential_to_aggregate
    locked_referential_to_aggregate || output.current
  end

  def calendars
    workgroup.calendars.where('(organisation_id = ? OR shared = ?)', organisation.id, true)
  end

  # XXX
  # def import_compliance_control_set
  #   import_compliance_control_set_id && ComplianceControlSet.find(import_compliance_control_set_id)
  # end

  def compliance_control_set key
    id = (owner_compliance_control_set_ids || {})[key.to_s]
    ComplianceControlSet.where(id: id).last if id.present?
  end

  def compliance_control_set_ids=(compliance_control_set_ids)
    self.owner_compliance_control_set_ids = (owner_compliance_control_set_ids || {}).merge compliance_control_set_ids
  end

  def sentinel_notifications_recipients
    users.map(&:email_recipient)
  end

  private

  def initialize_output
    self.output ||= ReferentialSuite.create
  end
end
