module Chouette
  class LinkOrientationType < TextAndNumericalType
    DEFINITIONS = [
      ["access_point_to_stop_area", 0],
      ["stop_area_to_access_point", 1],
    ].freeze
  end
end
