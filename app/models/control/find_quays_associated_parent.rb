# frozen_string_literal: true

module Control
  class FindQuaysAssociatedParent < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        option :geographical_distance, default_value: 100
        option :used_by_opposite_routes, default_value: false
        option :lexical_distance, default_value: 0

        validates :geographical_distance, numericality: { greater_than_or_equal_to: 50, less_than_or_equal_to: 150, allow_nil: false }
        validates :lexical_distance, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_nil: false }
      end
    end

    include Options

    class Run < Control::Base::Run
      include Options

      def run
        return unless referential

        anomalies.each do |anomaly|
          anomaly.grouped_stop_areas.each do |stop_area|
            messages.create(
              stop_area_name: stop_area['name'],
              short_id: Chouette::ObjectidFormatter::Netex.new.get_objectid(stop_area['objectid']).short_id,
              cluster_id: anomaly.cluster_id
            ) do |message|
              message[:source_id] = stop_area['stop_area_id']
              message[:source_type] = 'Chouette::StopArea'
            end
          end
        end
      end

      def anomalies
        PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
      end

      class Anomaly
        def initialize(attributes)
          attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
        end
        attr_accessor :cluster_id
        attr_writer :grouped_stop_areas

        def grouped_stop_areas
          return [] unless @grouped_stop_areas.present?
          JSON.parse(@grouped_stop_areas)
        rescue JSON::ParserError
          []
        end
      end

      def query
        @query ||= Query.new(
          context,
          geographical_distance,
          lexical_distance,
          used_by_opposite_routes
        ).clustered_stop_areas_query
      end

      class Query
        def initialize(context, geographical_distance, lexical_distance, used_by_opposite_routes)
          @context = context
          @geographical_distance = geographical_distance
          @lexical_distance = lexical_distance
          @used_by_opposite_routes = used_by_opposite_routes
        end
        attr_reader :context, :geographical_distance, :lexical_distance, :used_by_opposite_routes

        def clustered_stop_areas_query
          Chouette::StopArea
            .select(
              <<-SQL
                JSON_AGG(
                  JSON_BUILD_OBJECT(
                    'stop_area_id', stop_areas.id,
                    'name', stop_areas.name,
                    'objectid', stop_areas.objectid
                  )
                ) AS grouped_stop_areas,
                stop_areas.cluster_id
              SQL
            )
            .from("(#{raw_clustered_stop_areas}) stop_areas")
            .where.not("stop_areas.id IN (#{excluded_stop_areas})")
            .group('stop_areas.cluster_id')
            .having('count(*) > 1')
            .to_sql
        end

        # identify StopAreas used in the same Route (in the given Dataset)
        def excluded_stop_areas
          Chouette::StopArea
            .select('stop_areas.id')
            .from("(#{raw_clustered_stop_areas}) AS stop_areas")
            .joins(
              <<-SQL
                INNER JOIN (#{raw_clustered_stop_areas}) AS csa
                ON stop_areas.cluster_id = csa.cluster_id
                  AND stop_areas.route_ids && csa.route_ids
                  AND stop_areas.id <> csa.id
              SQL
            )
            .distinct
            .to_sql
        end

        def raw_clustered_stop_areas
          @raw_clustered_stop_areas ||= Chouette::StopArea
            .select('stop_areas.*')
            .from("(#{base_query}) stop_areas")
            .where('stop_areas.cluster_id IS NOT NULL')
            .to_sql
        end

        # prepare StopAreas grouped by transport_mode and geographical distance
        def base_query
          @base_query ||= stop_areas
            .select(
              <<-SQL
                public.stop_areas.id, public.stop_areas.objectid, public.stop_areas.name, ARRAY_AGG(routes.id) AS route_ids,
                ST_ClusterDBSCAN(
                  ST_Transform(
                    ST_SetSRID(
                      ST_MakePoint(public.stop_areas.longitude, public.stop_areas.latitude),
                      4326
                    ), 3857), #{geographical_distance}, 2
                ) OVER (
                  PARTITION BY #{partition_by}
                ) AS cluster_id
              SQL
            )
            .left_joins(base_left_joins)
            .where(base_where)
            .group('public.stop_areas.id, public.stop_areas.objectid, public.stop_areas.name')
            .to_sql
        end

        # partition by transport_mode and group_name (lexical distance)
        def partition_by
          <<-SQL
            public.stop_areas.transport_mode,
            (
              SELECT sa.name
              FROM public.stop_areas sa
              WHERE similarity(public.stop_areas.name, sa.name) >= #{threshold}
              ORDER BY sa.name
              LIMIT 1
            )
          SQL
        end

        # normalized lexical distance (0-1)
        def threshold
          @threshold ||= lexical_distance / 100.0
        end

        def base_left_joins
          @base_left_joins ||= used_by_opposite_routes ?  { routes: {opposite_route: :stop_areas} } : :routes
        end

        def base_where
          @base_where ||=
            if used_by_opposite_routes
              <<-SQL
                public.stop_areas.latitude IS NOT NULL AND
                public.stop_areas.longitude IS NOT NULL AND
                public.stop_areas.parent_id IS NULL AND
                public.stop_areas.area_type = 'zdep' AND
                public.stop_areas_routes.id = public.stop_areas.id AND
                public.stop_areas_routes.id IS NOT NULL
              SQL
           else
              <<-SQL
                public.stop_areas.latitude IS NOT NULL AND
                public.stop_areas.longitude IS NOT NULL AND
                public.stop_areas.parent_id IS NULL AND
                public.stop_areas.area_type = 'zdep'
              SQL
           end
        end

        def stop_areas
          @stop_areas ||= context.stop_areas
        end
      end
    end
  end
end
