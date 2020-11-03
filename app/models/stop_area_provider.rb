class StopAreaProvider < ActiveRecord::Base
  include ObjectidSupport

  belongs_to :stop_area_referential
  belongs_to :workbench, required: true

  has_many :stop_areas, class_name: "Chouette::StopArea"

  alias_method :referential, :stop_area_referential

  before_validation :define_line_referential, on: :create

  private

  def define_line_referential
    self.stop_area_referential ||= workbench&.stop_area_referential
  end

end
