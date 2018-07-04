module Chouette
  class ConnectionLinkType < TextAndNumericalType
    DEFINITIONS = [
      ["underground", 0],
      ["mixed", 1],
      ["overground", 2],
    ].freeze
  end
end
