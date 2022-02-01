class LineRoutingConstraintZone < ApplicationModel
  include LineReferentialSupport

  validates_presence_of :name

  has_array_of :stop_areas, class_name: 'Chouette::StopArea'
  has_array_of :lines, class_name: 'Chouette::Line'

end
