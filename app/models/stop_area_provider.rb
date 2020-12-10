class StopAreaProvider < ActiveRecord::Base
  # This before_validation callback needs to be declared before the one in ObjectidSupport, to prevent a crash if referential_identifier doesn't find the related stop area referential
  # I removed the on_create argument, since that callback needs to be fired even on initialize in workbench#create_dependencies
  before_validation :define_stop_area_referential
  include ObjectidSupport

  belongs_to :stop_area_referential
  belongs_to :workbench, required: true

  has_many :stop_areas, class_name: "Chouette::StopArea"

  # TODO Required by Chouette::Sync::Updater::Batch#resolver limitation
  alias_attribute :registration_number, :objectid
  delegate :workgroup, to: :stop_area_referential

  private

  def define_stop_area_referential
    self.stop_area_referential ||= workbench&.stop_area_referential
  end

end
