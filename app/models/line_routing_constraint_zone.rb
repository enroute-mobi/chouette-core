class LineRoutingConstraintZone < ApplicationModel
  include LineReferentialSupport

  has_array_of :stop_areas, class_name: 'Chouette::StopArea'
  has_array_of :lines, class_name: 'Chouette::Line'

  # delegate :stop_area_referential, to: :workgroup

end
