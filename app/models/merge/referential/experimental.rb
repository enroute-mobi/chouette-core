module Merge::Referential

  module Sanitizer
    def sanitize_joins(query)
      # in fact, new.slug is already sanitized but .. it is better to be safe than sorry.
      # sanitize_sql_array uses quotes and creates an invalid query (like LEFT OUTER JOIN 'referential_xyz'.vehicle_journeys)
      query.gsub(':new_slug', new.slug)
    end
  end

  class Experimental < Merge::Referential::Legacy

    def referential_inserter
      @referential_inserter ||= ReferentialInserter.new(new) do |config|
        config.add IdMapInserter, strict: false
        config.add ObjectidInserter
        config.add CopyInserter
      end
    end

    include Sanitizer
    def vehicle_journeys
      @vehicle_journeys ||=
        source.vehicle_journeys.joins(:journey_pattern, :route).
          joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".routes as existing_routes ON routes.checksum = existing_routes.checksum AND routes.line_id = existing_routes.line_id")).
          joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".journey_patterns as existing_journey_patterns ON journey_patterns.checksum = existing_journey_patterns.checksum AND existing_routes.id = existing_journey_patterns.route_id")).
          joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".vehicle_journeys as existing_vehicle_journeys ON vehicle_journeys.checksum = existing_vehicle_journeys.checksum AND existing_journey_patterns.id = existing_vehicle_journeys.journey_pattern_id")).
          where("existing_vehicle_journeys.id" => nil)
    end

    def merge_vehicle_journeys
      source.switch do
        VehicleJourneys.new(self).merge
        VehicleJourneyCodes.new(self).merge
        VehicleJourneyAtStops.new(self).merge
      end

      referential_inserter.flush
    end

    class Part

      def initialize(merge_context)
        @merge_context = merge_context
      end
      attr_reader :merge_context

      delegate :referential, :new, to: :merge_context
      alias source referential

      delegate :referential_inserter, :vehicle_journeys, to: :merge_context

      def part_name
        @part_name ||= self.class.name.demodulize.underscore
      end

      def merge
        Chouette::Benchmark.measure part_name do
          merge!
        end
      end

    end

    class VehicleJourneys < Part

      def merge!
        find_each do |vehicle_journey_merge|
          vehicle_journey = vehicle_journey_merge.vehicle_journey

          if vehicle_journey_merge.existing_objectid?
            vehicle_journey.objectid = nil
          end

          vehicle_journey.journey_pattern_id = vehicle_journey_merge.existing_journey_pattern_id
          vehicle_journey.route_id = vehicle_journey_merge.existing_route_id

          vehicle_journey.ignored_routing_contraint_zone_ids = vehicle_journey_merge.existing_ignored_routing_contraint_zone_ids

          referential_inserter.vehicle_journeys << vehicle_journey
        end
      end

      def find_each(&block)
        vehicle_journeys.order("route_id", "journey_pattern_id").each_instance_batch do |batch|
          Batch.new(self, batch).find_each(&block)
        end
      end

      # A Vehicle Journey with associated resources
      class Merge

        def initialize(vehicle_journey)
          @vehicle_journey = vehicle_journey
        end

        attr_accessor :vehicle_journey, :existing_objectid, :existing_journey_pattern_id, :existing_route_id
        alias existing_objectid? existing_objectid
        attr_accessor :existing_ignored_routing_contraint_zone_ids

      end

      class Batch < ::Merge::Referential::Batch

        alias vehicle_journeys models

        def route_and_journey_patterns
          @route_and_journey_patterns ||= RouteAndJourneyPatterns.new(self)
        end
        delegate :existing_route_id, :existing_journey_pattern_id, to: :route_and_journey_patterns

        def ignored_routing_contraint_zones
          @ignored_routing_contraint_zones ||= IgnoredRoutingContraintZones.new(self)
        end
        delegate :existing_ignored_routing_contraint_zone_ids, to: :ignored_routing_contraint_zones

        def object_ids
          @duplicated_object_ids ||= ExistingObjectIDs.new(self)
        end
        delegate :existing_objectid?, to: :object_ids

        def find_each
          vehicle_journeys.each do |vehicle_journey|
            merge = Merge.new vehicle_journey

            merge.existing_objectid = existing_objectid?(vehicle_journey.id)
            merge.existing_route_id = existing_route_id(vehicle_journey.route_id)
            merge.existing_journey_pattern_id = existing_journey_pattern_id(vehicle_journey.journey_pattern_id)

            merge.existing_ignored_routing_contraint_zone_ids =
              existing_ignored_routing_contraint_zone_ids(vehicle_journey.ignored_routing_contraint_zone_ids)

            yield merge
          end
        end

      end

      class BatchAssociation < ::Merge::Referential::BatchAssociation
        delegate :vehicle_journeys, to: :batch
      end

      class RouteAndJourneyPatterns < BatchAssociation

        def rows
          source.journey_patterns.joins(:route).
            joins("LEFT OUTER JOIN \"#{new.slug}\".routes as existing_routes ON routes.checksum = existing_routes.checksum AND routes.line_id = existing_routes.line_id").
            joins("LEFT OUTER JOIN \"#{new.slug}\".journey_patterns as existing_journey_patterns ON journey_patterns.checksum = existing_journey_patterns.checksum AND existing_routes.id = existing_journey_patterns.route_id").
            where(id: journey_pattern_ids).pluck(:id, "routes.id", "existing_journey_patterns.id", "existing_routes.id")
        end

        def load
          return if @loaded
          @loaded = true
          rows.each do |journey_pattern_id, route_id, existing_journey_pattern_id, existing_route_id|
            existing_route_ids[route_id] = existing_route_id
            existing_journey_pattern_ids[journey_pattern_id] = existing_journey_pattern_id
          end
        end

        def journey_pattern_ids
          vehicle_journeys.map(&:journey_pattern_id).uniq
        end

        def existing_route_ids
          load
          @existing_route_ids ||= {}
        end

        def existing_route_id(vehicle_journey_id)
          existing_route_ids.fetch vehicle_journey_id
        end

        def existing_journey_pattern_ids
          load
          @existing_journey_pattern_ids ||= {}
        end

        def existing_journey_pattern_id(vehicle_journey_id)
          existing_journey_pattern_ids.fetch vehicle_journey_id
        end

      end

      class IgnoredRoutingContraintZones < BatchAssociation

        include Sanitizer

        def ignored_routing_contraint_zone_ids
          @ignored_routing_contraint_zone_ids ||= vehicle_journeys.map(&:ignored_routing_contraint_zone_ids).flatten.uniq
        end

        def rows
          source.routing_constraint_zones.
            joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".routing_constraint_zones as existing_routing_constraint_zones ON routing_constraint_zones.checksum = existing_routing_constraint_zones.checksum")).
            where(id: ignored_routing_contraint_zone_ids).pluck("routing_constraint_zones.id", "existing_routing_constraint_zones.id")
        end

        def all_existing_ignored_routing_contraint_zone_ids
          @existing_ignored_routing_contraint_zone_ids ||= Hash[rows]
        end

        def existing_ignored_routing_contraint_zone_ids(ignored_routing_contraint_zone_ids)
          all_existing_ignored_routing_contraint_zone_ids.values_at(*ignored_routing_contraint_zone_ids).compact
        end

      end

      class ExistingObjectIDs < BatchAssociation

        include Sanitizer

        def rows
          source.vehicle_journeys.
            joins(sanitize_joins("INNER JOIN \":new_slug\".vehicle_journeys as existing_vehicle_journeys ON vehicle_journeys.objectid = existing_vehicle_journeys.objectid")).
            where(id: vehicle_journeys).pluck(:id)
        end

        def with_existing_objectid_ids
          @with_existing_objectid_ids ||= SortedSet.new(rows)
        end

        def existing_objectid?(vehicle_journey_id)
          with_existing_objectid_ids.include? vehicle_journey_id
        end

      end

    end

    class VehicleJourneyAtStops < Part

      def merge!
        find_each do |vehicle_journey_at_stop_merge|
          vehicle_journey_at_stop = vehicle_journey_at_stop_merge.vehicle_journey_at_stop
          vehicle_journey_at_stop.stop_point_id = vehicle_journey_at_stop_merge.existing_stop_point_id

          referential_inserter.vehicle_journey_at_stops << vehicle_journey_at_stop
        end
      end

      def vehicle_journey_at_stops
        source.vehicle_journey_at_stops.where(vehicle_journey: vehicle_journeys)
      end

      def find_each(&block)
        vehicle_journey_at_stops.joins(:vehicle_journey).order("vehicle_journeys.route_id").each_instance_batch do |batch|
          Batch.new(self, batch).find_each(&block)
        end
      end

      class Merge

        def initialize(vehicle_journey_at_stop)
          @vehicle_journey_at_stop = vehicle_journey_at_stop
        end

        attr_accessor :vehicle_journey_at_stop, :existing_stop_point_id

      end

      class Batch < ::Merge::Referential::Batch

        alias vehicle_journey_at_stops models

        def stop_points
          @stop_points ||= StopPoints.new(self)
        end
        delegate :existing_stop_point_id, to: :stop_points

        def find_each
          vehicle_journey_at_stops.each do |vehicle_journey_at_stop|
            merge = Merge.new vehicle_journey_at_stop
            merge.existing_stop_point_id = existing_stop_point_id(vehicle_journey_at_stop.stop_point_id)

            yield merge
          end
        end

      end

      class BatchAssociation < ::Merge::Referential::BatchAssociation
        delegate :vehicle_journey_at_stops, to: :batch
      end

      class StopPoints < BatchAssociation

        def sql
          <<-SQL
        SELECT stop_point_id, existing_stop_point_id FROM
        (
          SELECT stop_points.id as stop_point_id, routes.checksum as route_checksum,
            ROW_NUMBER () OVER (
          		PARTITION BY route_id
          		ORDER BY position
          	) normalized_position
          from "stop_points"
          INNER JOIN "routes" ON "routes"."id" = "stop_points"."route_id"
          WHERE "stop_points"."id" IN (#{stop_point_ids_bind_params})
          order by route_id, stop_points.position
        ) source_stop_points
        join
        (
          SELECT existing_stop_points.id as existing_stop_point_id, existing_routes.checksum as route_checksum,
            ROW_NUMBER () OVER (
          		PARTITION BY existing_stop_points.route_id
          		ORDER BY existing_stop_points.position
          	) normalized_position
          from \"#{new.slug}\".stop_points as existing_stop_points
          LEFT OUTER JOIN \"#{new.slug}\".routes as existing_routes ON existing_routes.id = existing_stop_points.route_id
          LEFT OUTER JOIN routes ON routes.checksum = existing_routes.checksum
          INNER JOIN (SELECT distinct route_id from stop_points WHERE id IN (#{stop_point_ids_bind_params})) source_stop_points ON source_stop_points.route_id = routes.id
        ) existing_stop_points
        ON
          source_stop_points.route_checksum = existing_stop_points.route_checksum
          AND source_stop_points.normalized_position = existing_stop_points.normalized_position
      SQL
        end

        def rows
          Chouette::StopPoint.connection.select_rows sql, "Load Existing StopPoints", stop_point_ids_binds
        end

        def stop_point_ids_binds
          stop_point_ids.map do |stop_point_id|
            [nil, stop_point_id]
          end
        end

        def stop_point_ids_bind_params
          @stop_point_ids_bind_params ||= stop_point_ids.count.times.map do |n|
            "$#{n+1}"
          end.join(',')
        end

        def stop_point_ids
          @stop_point_ids ||= vehicle_journey_at_stops.map(&:stop_point_id).uniq
        end

        def existing_stop_point_ids
          @existing_stop_point_ids ||= Hash[rows]
        end

        def existing_stop_point_id(stop_point_id)
          existing_stop_point_ids.fetch stop_point_id
        end

      end

    end

    class VehicleJourneyCodes < Part
      include Sanitizer

      def merge!
        codes.find_each do |code|
          referential_inserter.codes << code
        end
      end

      def codes
        source.referential_codes.where(resource_type: 'Chouette::VehicleJourney').
          joins("INNER JOIN vehicle_journeys ON referential_codes.resource_id = vehicle_journeys.id").
          joins("INNER JOIN journey_patterns ON vehicle_journeys.journey_pattern_id = journey_patterns.id").
          joins("INNER JOIN routes ON journey_patterns.route_id = routes.id").
          joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".routes as existing_routes ON routes.checksum = existing_routes.checksum AND routes.line_id = existing_routes.line_id")).
          joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".journey_patterns as existing_journey_patterns ON journey_patterns.checksum = existing_journey_patterns.checksum AND existing_routes.id = existing_journey_patterns.route_id")).
          joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".vehicle_journeys as existing_vehicle_journeys ON vehicle_journeys.checksum = existing_vehicle_journeys.checksum AND existing_journey_patterns.id = existing_vehicle_journeys.journey_pattern_id")).
          joins(sanitize_joins("LEFT OUTER JOIN \":new_slug\".referential_codes as existing_codes ON referential_codes.code_space_id = existing_codes.code_space_id AND referential_codes.value = existing_codes.value AND existing_vehicle_journeys.id = existing_codes.resource_id AND existing_codes.resource_type = 'Chouette::VehicleJourney'")).
          where("existing_codes.id" => nil)
      end
    end
  end
end
