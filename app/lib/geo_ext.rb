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

    def self.from(position)
      if position.respond_to?(:latitude) && position.respond_to?(:longitude)
        Geo::Position.new latitude: position.latitude.to_f, longitude: position.longitude.to_f
      end
    end

    alias lat latitude
    alias lon longitude

    def to_point
      "POINT(#{x} #{y})"
    end

    def to_s
      "#{latitude},#{longitude}"
    end

    def valid?
      (-90..90).include?(latitude) &&
        (-180..180).include?(longitude)
    end

    def self.centroid(positions)
      latitude = positions.sum(&:latitude) / positions.count
      longitude = positions.sum(&:longitude) / positions.count

      new latitude: latitude, longitude: longitude
    end

    def distance_with(other)
      self.class.distance_between self, other
    end
    alias - distance_with

    # TODO Use your own computation
    def self.distance_between(from, to)
      Geokit::GeoLoc.distance_between([from.latitude, from.longitude], [to.latitude, to.longitude], units: :kms) * 1000
    end

  end
end
