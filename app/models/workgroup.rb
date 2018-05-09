class Workgroup < ApplicationModel
  belongs_to :line_referential
  belongs_to :stop_area_referential

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

  def custom_fields_definitions
    Hash[*custom_fields.map{|cf| [cf.code, cf]}.flatten]
  end

  def has_export? export_name
    export_types.include? export_name
  end

  def import_compliance_control_sets
    @import_compliance_control_sets ||= import_compliance_control_set_ids.map{|id| ComplianceControlSet.find(id)}
  end
end
