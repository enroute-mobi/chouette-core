class StopAreaProvider < ActiveRecord::Base
  include ObjectidSupport

  belongs_to :stop_area_referential
  belongs_to :workbench, required: true

  has_many :stop_areas, class_name: "Chouette::StopArea"

  alias referential stop_area_referential
  # Used as a workaround to prevent spec/lib/chouette/sync/updater_spec.rb to crash
  alias_attribute :registration_number, :objectid

  before_validation :define_stop_area_referential, on: :create

  private

  def define_stop_area_referential
    self.stop_area_referential ||= workbench&.stop_area_referential
  end

end
