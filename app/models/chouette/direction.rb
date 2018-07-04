module Chouette
  class Direction < TextAndNumericalType
    DEFINITIONS = [
      ["straight_forward", 0],
      ["backward", 1],
      ["clock_wise", 2],
      ["counter_clock_wise", 3],
      ["north", 4],
      ["north_west", 5],
      ["west", 6],
      ["south_west", 7],
      ["south", 8],
      ["south_east", 9],
      ["east", 10],
      ["north_east", 11],
    ].freeze

    def name
      to_s
    end
  end
end
