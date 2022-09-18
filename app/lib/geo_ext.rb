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
        return Geo::Position.new latitude: position.latitude.to_f, longitude: position.longitude.to_f
      end
      if position.respond_to?(:x) && position.respond_to?(:y)
        return Geo::Position.new x: position.x.to_f, y: position.y.to_f
      end
      if position.is_a?(Array)
        return Geo::Position.new latitude: position[0], longitude: position[1] 
      end
      raise "Unsupported value: #{position.inspect}"
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

  # Represents several ordered positions
  class Line
    include Enumerable

    def positions
      @positions ||= []
    end

    def each(&block)
      positions.each(&block)
    end

    def self.from_rgeos(line_string)
      new.tap do |line|
        line_string.points.each do |point|
          line.positions << Position.from(point)
        end
      end
    end

    # Create a Line from given values:
    #
    #   Geo::Line.from([48.858093, 2.294694], [48.858094, 2.294695])
    def self.from(values)
      new.tap do |line|
        values.each do |value|
          line.positions << Position.from(value)
        end
      end
    end

    # TODO: very limited implementation
    def maximum_distance_with(other)
      positions.map.each_with_index do |position, index|
        other_position = other.positions[index]
        position.distance_with(other_position)
      end.max
    end
    alias - maximum_distance_with
  end
end
