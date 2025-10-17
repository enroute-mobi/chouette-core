# frozen_string_literal: true

module Control
  class FindQuaysAssociatedParent < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        option :geographical_distance, serialize: ActiveModel::Type::Integer
        option :used_by_opposite_routes, serialize: ActiveModel::Type::Boolean, default: false
        option :lexical_distance, serialize: ActiveModel::Type::Integer, default: 0

        validates :geographical_distance, numericality: { greater_than_or_equal_to: 50, less_than_or_equal_to: 1000 }
        validates :lexical_distance, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
      end
    end

    include Options

    class Run < Control::Base::Run
      include Options

      def run
        anomalies.each do |anomaly|
          anomaly.grouped_stop_areas.each do |stop_area|
            control_messages.create({
              message_attributes: {
                stop_area_name: stop_area['name'],
                short_id: Chouette::ObjectidFormatter::Netex.new.get_objectid(stop_area['objectid']).short_id,
                cluster_id: anomaly.cluster_id
              },
              criticity: criticity,
              source_id: stop_area['stop_area_id'],
              source_type: 'Chouette::StopArea',
              message_key: :find_quays_associated_parent
            })
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
          workbench,
          geographical_distance,
          lexical_distance,
          used_by_opposite_routes
        ).clustered_stop_areas_query
      end

      class Query
        def initialize(workbench, geographical_distance, lexical_distance, used_by_opposite_routes)
          @workbench = workbench
          @geographical_distance = geographical_distance
          @lexical_distance = lexical_distance
          @used_by_opposite_routes = used_by_opposite_routes
        end
        attr_reader :workbench, :geographical_distance, :lexical_distance, :used_by_opposite_routes

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
            .where.not('stop_areas.cluster_id IS NULL')
            .where.not("stop_areas.id IN (#{excluded_stop_areas})")
            .group('stop_areas.cluster_id')
            .to_sql
        end

        # identify StopAreas used in the same Route (in the given Dataset)
        def excluded_stop_areas
          @stop_areas_used_same_route ||= Chouette::StopArea
            .select('stop_areas.id')
            .from("(#{raw_clustered_stop_areas}) AS stop_areas")
            .joins(
              <<-SQL
                INNER JOIN (#{raw_clustered_stop_areas}) AS csa
                ON stop_areas.cluster_id = csa.cluster_id
                  AND stop_areas.route_ids && csa.route_ids
                  AND ARRAY_LENGTH(stop_areas.route_ids, 1) > 1
                  AND ARRAY_LENGTH(csa.route_ids, 1) > 1
                  AND stop_areas.id <> csa.id
              SQL
            )
            .distinct
            .to_sql
        end

        def raw_clustered_stop_areas
          @clustered_stop_areas ||= Chouette::StopArea
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
                stop_areas.id, stop_areas.objectid, stop_areas.name, ARRAY_AGG(routes.id) AS route_ids,
                ST_ClusterDBSCAN(
                  ST_Transform(
                    ST_SetSRID(
                      ST_MakePoint(stop_areas.longitude, stop_areas.latitude),
                      4326
                    ), 3857), #{geographical_distance}, 2
                ) OVER (
                  PARTITION BY #{partition_by}
                ) AS cluster_id
              SQL
            )
            .left_joins(base_left_joins)
            .where(base_where)
            .group('public.stop_areas.id')
            .to_sql
        end

        # partition by transport_mode and group_name (lexical distance)
        def partition_by
          <<-SQL
            stop_areas.transport_mode,
            (
              SELECT sa.name
              FROM public.stop_areas sa
              WHERE similarity(stop_areas.name, sa.name) >= #{threshold}
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
          @left_joins ||= used_by_opposite_routes ?  { routes: {opposite_route: :stop_areas} } : :routes
        end

        def base_where
          @base_where ||=
            if used_by_opposite_routes
              <<-SQL
                stop_areas.latitude IS NOT NULL AND
                stop_areas.longitude IS NOT NULL AND
                stop_areas.parent_id IS NULL AND
                stop_areas.area_type = 'zdep' AND
                stop_areas_routes.id = stop_areas.id AND
                stop_areas_routes.id IS NOT NULL
              SQL
           else
              <<-SQL
                stop_areas.latitude IS NOT NULL AND
                stop_areas.longitude IS NOT NULL AND
                stop_areas.parent_id IS NULL AND
                stop_areas.area_type = 'zdep'
              SQL
           end
        end

        def stop_areas
          @stop_areas ||= workbench.stop_areas
        end
      end
    end
  end
end



