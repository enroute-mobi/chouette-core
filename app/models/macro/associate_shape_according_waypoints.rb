# frozen_string_literal: true

module Macro
  class AssociateShapeAccordingWaypoints < Macro::Base
    class Run < Macro::Base::Run
      def run
        journey_patterns.find_each do |journey_pattern|
          if shape = Finder.new(journey_pattern, shapes).shape
            journey_pattern.update shape_id: shape.id
            create_message(journey_pattern, shape)
          end
        end
      end

      def create_message(journey_pattern, shape)
        attributes = {
          message_attributes: { name: journey_pattern.name, shape: shape.user_name },
          source: journey_pattern
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless journey_pattern.valid?

        macro_messages.create!(attributes)
      end

      class Finder
        def initialize(journey_pattern, shapes)
          @journey_pattern = journey_pattern
          @shapes = shapes
        end
        attr_reader :journey_pattern, :shapes

        def shape
          if attributes = shapes[stop_area_sequence]
            @shape ||= Shape.new attributes
          end
        end

        def stop_area_sequence
          @stop_area_sequence ||= journey_pattern.waypoints.map(&:stop_area_id).join('-')
        end

        class Shape
          def initialize(id: nil, user_name: nil)
            @id = id
            @user_name = user_name
          end
          attr_reader :id, :user_name
        end
      end

      def journey_patterns
        @journey_patterns ||= scope.journey_patterns
                                   .without_associated_shape
                                   .includes(stop_points: :stop_area)
      end

      def shapes
        @shapes ||= Shapes.for(workgroup).shapes
      end

      class Shapes
        def self.for(workgroup)
          new workgroup
        end

        def initialize(workgroup)
          @workgroup = workgroup
        end
        attr_reader :workgroup

        delegate :shape_referential, to: :workgroup

        def shapes
            {}.tap do |shapes|
              ::Shape.select('stop_area_sequence, id, name, uuid').from(custom_from).each do |shape|
                if stop_area_sequence = shape.stop_area_sequence.presence
                  shapes[stop_area_sequence] = { id: shape.id, user_name: (shape.name || shape.uuid) }
                end
              end
            end
        end

        def custom_from
          <<~SQL
            (
              WITH latest_shapes AS (
                SELECT 
                  MAX(shapes.id) AS id,
                  shapes.stop_area_sequence AS stop_area_sequence
                FROM (#{base_sql}) AS shapes
                GROUP BY shapes.stop_area_sequence
              )
              SELECT
                public.shapes.*,
                latest_shapes.stop_area_sequence
              FROM latest_shapes INNER JOIN public.shapes ON latest_shapes.id = public.shapes.id
            ) AS shapes
          SQL
        end

        private

        def base_sql
          select = "public.shapes.*, array_to_string(array_agg(public.waypoints.stop_area_id order by position),'-') AS stop_area_sequence"
          scope.select(select).group(:id).joins(:waypoints).where.not('waypoints.stop_area_id' => nil).to_sql
        end

        def scope
          shape_referential.shapes
        end
      end
    end
  end
end