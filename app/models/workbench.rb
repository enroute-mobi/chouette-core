class Workbench < ApplicationModel
  DEFAULT_WORKBENCH_NAME = "Gestion de l'offre"

  include ObjectidFormatterSupport
  belongs_to :organisation
  belongs_to :line_referential
  belongs_to :stop_area_referential
  belongs_to :output, class_name: 'ReferentialSuite'
  belongs_to :workgroup

  has_many :lines, -> (workbench) { Stif::MyWorkbenchScopes.new(workbench).line_scope(self) }, through: :line_referential
  has_many :networks, through: :line_referential
  has_many :companies, through: :line_referential
  has_many :group_of_lines, through: :line_referential
  has_many :stop_areas, through: :stop_area_referential
  has_many :imports, class_name: Import::Base
  has_many :exports, class_name: Export::Base
  has_many :workbench_imports, class_name: Import::Workbench
  has_many :compliance_check_sets
  has_many :compliance_control_sets
  has_many :merges

  validates :name, presence: true
  validates :organisation, presence: true
  validates :output, presence: true

  has_many :referentials
  has_many :referential_metadatas, through: :referentials, source: :metadatas

  before_validation :initialize_output


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
    where(name: DEFAULT_WORKBENCH_NAME).last
  end

  private

  def initialize_output
    # Don't reset `output` if it's already initialised
    return if !output.nil?

    self.output = ReferentialSuite.create
  end
end
