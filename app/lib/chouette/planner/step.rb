# frozen_string_literal: true

module Chouette
  module Planner
    module Step
      def self.for(definition, **attributes)
        case definition
        when Chouette::StopArea
          StopArea.for definition
        else
          Base.new position: Geo::Position.parse(definition), **attributes
        end
      end

      class Base
        attr_accessor :duration, :created_by

        def initialize(attributes = {})
          self.duration = 0

          attributes.each { |k, v| send "#{k}=", v }
        end

        def id
          @id ||= SecureRandom.uuid
        end
        attr_writer :id

        attr_reader :position

        def position=(position)
          @position = Geo::Position.from position
        end

        def distance_with(other)
          position.distance_with(other.position)
        end

        def ==(other)
          distance_with(other) < 10
        end

        def validity_period
          @validity_period ||= ValidityPeriod.new
        end
        attr_writer :validity_period

        def inspect
          "#{@position} ⏱️#{duration}s"
        end

        def with_duration(duration)
          clone = dup
          clone.id = nil
          clone.duration = duration
          clone
        end
      end

      class StopArea < Base
        def self.for(stop_area)
          new stop_area_id: stop_area.id, position: stop_area
        end

        attr_accessor :stop_area_id

        def id
          @id ||= "stop_area:#{stop_area_id}"
        end

        def inspect
          "🚏#{stop_area_id} #{super}"
        end
      end
    end
  end
end
