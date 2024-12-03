# TODO To be shared (with netex gem especially)
require 'geo'

module Geo
  class Position
    FORMAT = /\A *(?<first>-?[0-9]+(?>\.[0-9]+)?) *[,: ] *(?<second>-?[0-9]+(?>\.[0-9]+)?) *\Z/.freeze

    def self.parse(definition)
      if FORMAT =~ definition
        Geo::Position.new latitude: ::Regexp.last_match(1).to_f, longitude: ::Regexp.last_match(2).to_f
      end
    end

    def self.from(position)
      return nil unless position

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
    alias lng longitude

    def to_point
      "POINT(#{x} #{y})"
    end

    def to_sql
      "ST_SetSRID(ST_Point(#{longitude}, #{latitude}), 4326)"
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

    EARTH_RADIUS = 6371.0

    # https://github.com/alexreisner/geocoder/blob/e4e2a884e54b4463387a19e44f3bcec9bd4219ac/lib/geocoder/calculations.rb
    def endpoint(heading:, distance:)
      latitude_radian, longitude_radian, heading = to_radians(latitude, longitude, heading)
      distance_rate = distance.to_f/EARTH_RADIUS/1000

      end_latitude_radian = Math.asin(Math.sin(latitude_radian)*Math.cos(distance_rate) +
                    Math.cos(latitude_radian)*Math.sin(distance_rate)*Math.cos(heading))

      end_longitude_radian = longitude_radian + Math.atan2(Math.sin(heading)*Math.sin(distance_rate)*Math.cos(latitude_radian),
                    Math.cos(distance_rate)-Math.sin(latitude_radian)*Math.sin(end_latitude_radian))

      end_latitude, end_longitude = to_degrees(end_latitude_radian, end_longitude_radian)
      self.class.new latitude: end_latitude, longitude: end_longitude
    end

    def around(heading: nil, distance: nil)
      heading ||= rand(0..360)
      distance ||= 500

      endpoint(heading: heading, distance: distance)
    end

    private

    def to_radians(*values)
      if values.size == 1
        values.first * (Math::PI / 180)
      else
        values.map { |value| value * (Math::PI / 180) }
      end
    end

    def to_degrees(*values)
      if values.size == 1
        (values.first * 180.0) / Math::PI
      else
        values.map{ |value| to_degrees(value) }
      end
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

  module Matchers
    class BeDistantOf
      def initialize(distance, tolerance: 10)
        @distance = distance
        @tolerance = tolerance
      end

      def of(target)
        @target = target

        self
      end

      attr_accessor :distance, :tolerance, :target

      def matches?(position)
        @position = position

        (position.distance_with(target) - distance).abs < tolerance
      end

      def description
        "be distant of #{distance}m from #{target}"
      end

      def failure_message
        "expected #{position} to #{description}"
      end

      def failure_message_when_negated
        "expected #{position} not to #{description}"
      end
    end

    def be_distant_of(distance, **options)
      BeDistantOf.new(distance, **options)
    end
  end
end
