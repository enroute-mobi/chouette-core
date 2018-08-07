class Workbench < ApplicationModel
  DEFAULT_WORKBENCH_NAME = "Gestion de l'offre"

  include ObjectidFormatterSupport
  belongs_to :organisation
  belongs_to :line_referential
  belongs_to :stop_area_referential
  belongs_to :output, class_name: 'ReferentialSuite'
  belongs_to :workgroup

  has_many :lines, -> (workbench) { workbench.workbench_scopes.lines_scope(self) }, through: :line_referential
  has_many :stop_areas, -> (workbench) { workbench.workbench_scopes.stop_areas_scope(self) }, through: :stop_area_referential
  has_many :networks, through: :line_referential
  has_many :companies, through: :line_referential
  has_many :group_of_lines, through: :line_referential
  has_many :imports, class_name: Import::Base, dependent: :destroy
  has_many :exports, class_name: Export::Base, dependent: :destroy
  has_many :workbench_imports, class_name: Import::Workbench, dependent: :destroy
  has_many :compliance_check_sets, dependent: :destroy
  has_many :merges, dependent: :destroy
  has_many :api_keys

  validates :name, presence: true
  validates :organisation, presence: true
  validates :prefix, presence: true
  validates :output, presence: true

  has_many :referentials, dependent: :destroy
  has_many :referential_metadatas, through: :referentials, source: :metadatas

  before_validation :initialize_output

  def workbench_scopes
    workgroup.workbench_scopes(self)
  end

  def all_referentials
    if line_ids.empty?
      Referential.none
    else
      workgroup
        .referentials
        .joins(:metadatas)
        .where(['referential_metadata.line_ids && ARRAY[?]::bigint[]', line_ids])
        .not_in_referential_suite
    end
  end

  def calendars
    workgroup.calendars.where('(organisation_id = ? OR shared = ?)', organisation.id, true)
  end

  def self.default
    self.last if self.count == 1
    where(name: DEFAULT_WORKBENCH_NAME).last || last
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

  private

  def initialize_output
    # Don't reset `output` if it's already initialised
    return if !output.nil?

    self.output = ReferentialSuite.create
  end
end
