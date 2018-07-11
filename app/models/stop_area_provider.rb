class StopAreaProvider < ActiveRecord::Base
  include ObjectidSupport

  belongs_to :stop_area_referential
  # join_table is required for the moment. see #7587
  has_and_belongs_to_many :stop_areas, class_name: "Chouette::StopArea", join_table: "public.stop_areas_stop_area_providers"

  alias_method :referential, :stop_area_referential
end
