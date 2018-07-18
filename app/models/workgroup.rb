class Workgroup < ApplicationModel
  belongs_to :line_referential
  belongs_to :stop_area_referential
  belongs_to :owner, class_name: "Organisation"

  has_many :workbenches, dependent: :destroy
  has_many :calendars, dependent: :destroy
  has_many :organisations, through: :workbenches
  has_many :referentials, through: :workbenches

  validates_uniqueness_of :name

  validates_presence_of :line_referential_id
  validates_presence_of :stop_area_referential_id
  validates_uniqueness_of :stop_area_referential_id
  validates_uniqueness_of :line_referential_id

  has_many :custom_fields

  accepts_nested_attributes_for :workbenches

  @@workbench_scopes_class = Stif::WorkbenchScopes
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

  def self.all_compliance_control_sets_labels
    compliance_control_sets_labels all_compliance_control_sets
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

  private
  def self.compliance_control_sets_label(key)
    "workgroups.compliance_control_sets.#{key}".t.capitalize
  end

  def self.compliance_control_sets_labels(keys)
    keys.inject({}) do |h, k|
      h[k] = compliance_control_sets_label(k)
      h
    end
  end

end
