# TODO To be shared (with netex gem especially)
require 'geo'

module Geo
  class Position
    FORMAT = /\A *([0-9]+\.[0-9]+) *[,:]? *([0-9]+\.[0-9]+) *\Z/
    def self.parse(definition)
      if FORMAT =~ definition
        Geo::Position.new latitude: $1.to_f, longitude: $2.to_f
      end
    end

    def to_point
      "POINT(#{x} #{y})"
    end

    def valid?
      (-90..90).include?(latitude) &&
        (-180..180).include?(longitude)
    end
  end
end
