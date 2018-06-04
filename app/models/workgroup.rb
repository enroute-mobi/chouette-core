class Workgroup < ApplicationModel
  belongs_to :line_referential
  belongs_to :stop_area_referential
  belongs_to :owner, class_name: "Organisation"

  has_many :workbenches
  has_many :calendars
  has_many :organisations, through: :workbenches
  has_many :referentials, through: :workbenches

  validates_uniqueness_of :name

  validates_presence_of :line_referential_id
  validates_presence_of :stop_area_referential_id
  validates_uniqueness_of :stop_area_referential_id
  validates_uniqueness_of :line_referential_id

  has_many :custom_fields

  accepts_nested_attributes_for :workbenches

  def custom_fields_definitions
    Hash[*custom_fields.map{|cf| [cf.code, cf]}.flatten]
  end

  def has_export? export_name
    export_types.include? export_name
  end

  def all_compliance_control_sets
    %i(after_import
      after_import_by_workgroup
      before_merge
      before_merge_by_workgroup
      after_merge
      after_merge_by_workgroup
      automatic_by_workgroup
    )
  end

  def compliance_control_sets_by_workgroup
    compliance_control_sets_labels all_compliance_control_sets.grep(/by_workgroup$/)
  end

  def compliance_control_sets_by_workbench
    compliance_control_sets_labels all_compliance_control_sets.grep_v(/by_workgroup$/)
  end

  def import_compliance_control_sets
    compliance_control_sets_labels all_compliance_control_sets.grep(/^after_import/)
  end

  def before_merge_compliance_control_sets
    compliance_control_sets_labels all_compliance_control_sets.grep(/^before_merge/)
  end

  def after_merge_compliance_control_sets
    compliance_control_sets_labels all_compliance_control_sets.grep(/^after_merge/)
  end

  private
  def compliance_control_sets_labels(keys)
    keys.inject({}) do |h, k|
      h[k] = "workgroups.compliance_control_sets.#{k}".t.capitalize
      h
    end
  end
end
