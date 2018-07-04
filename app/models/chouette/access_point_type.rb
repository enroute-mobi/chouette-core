module Chouette
  class AccessPointType < TextAndNumericalType
    DEFINITIONS = [
      ["in", 0],
      ["out", 1],
      ["in_out", 2],
    ].freeze
  end
end
