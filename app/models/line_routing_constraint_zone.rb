class LineRoutingConstraintZone < ApplicationModel
  include LineReferentialSupport

  validates :name, :line_ids, :stop_area_ids, presence: true

  has_array_of :stop_areas, class_name: 'Chouette::StopArea'
  has_array_of :lines, class_name: 'Chouette::Line'
end
