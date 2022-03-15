module Macro
  class CreateStopAreaReferents < Base
    class Run < Macro::Base::Run

      def run
        geo_clusters.each do |geo_cluster|
          geo_cluster.compass_bearing_clusters.each do |cluster|
            if cluster.count > 1
              builder = ReferentBuilder.create(cluster.stop_areas)
              if builder
                # TODO Create message
                stop_area_provider.stop_areas.create!(builder.attributes)
              end
            end
          end
        end
      end

      def stop_area_provider
        workbench.default_stop_area_provider
      end

      def stop_areas
        context.stop_areas.where(area_type: Chouette::AreaType::QUAY).
          where.not(latitude: nil, longitude: nil, compass_bearing: nil)
      end

      # Creates a cluster with ~20 meters between two positions
      def cluster_distance
        0.0002
      end

      def raw_clusterized_stop_areas
        query = <<~SQL
          SELECT geo_cluster, id, latitude, longitude, compass_bearing, is_referent, name, area_type
          FROM (
            SELECT id, latitude, longitude, compass_bearing, is_referent, name, area_type,
                  ST_ClusterDBSCAN(ST_SetSRID(ST_Point(longitude, latitude), 4326), #{cluster_distance}, 2) over () AS geo_cluster
            FROM public.stop_areas
            WHERE id IN (#{stop_areas.select(:id).to_sql})
          ) AS clusters
          WHERE geo_cluster IS NOT NULL;
        SQL

        Chouette::StopArea.connection.select_all(query)
      end

      def geo_clusters
        [].tap do |clusters|
          raw_clusterized_stop_areas.group_by { |r| r.delete "geo_cluster" }.map do |_, stop_areas_attributes|
            cluster = GeoCluster.new

            stop_areas_attributes.each do |stop_area_attributes|
              cluster.stop_areas << Chouette::StopArea.new(stop_area_attributes)
            end

            clusters << cluster
          end
        end
      end

      class GeoCluster
        def centroid
          @centroid ||= Geo::Position.centroid(stop_areas)
        end

        def max_distance
          stop_areas.map do |stop_area|
            centroid.distance_with stop_area
          end.max
        end

        def stop_areas
          @stop_areas ||= []
        end

        def compass_bearing_clusters
          @compass_bearing_clusters ||= CompassBearingCluster.compute(stop_areas)
        end
      end

      class CompassBearingCluster
        def initialize(stop_area)
          stop_areas << stop_area
        end

        def compass_bearing
          @compass_bearing ||= stop_areas.sum(&:compass_bearing) / count
        end

        def count
          stop_areas.count
        end

        def accept?(stop_area)
          angle_delta = ((stop_area.compass_bearing-compass_bearing+180) % 360 - 180).abs
          angle_delta <= compass_bearing_delta
        end

        def compass_bearing_delta
          7.5
        end

        def reset
          @compass_bearing = nil
        end

        def stop_areas
          @stop_areas ||= []
        end

        def push(stop_area)
          stop_areas << stop_area
          reset
        end
        alias << push

        def centroid
          @centroid ||= Geo::Position.centroid(stop_areas)
        end

        def max_distance
          stop_areas.map do |stop_area|
            centroid.distance_with stop_area
          end.max
        end

        def self.compute(stop_areas)
          clusters = []

          stop_areas.each do |stop_area|
            cluster = clusters.find { |c| c.accept? stop_area }

            if cluster
              cluster << stop_area
            else
              clusters << CompassBearingCluster.new(stop_area)
            end
          end

          clusters
        end
      end

      class ReferentBuilder

        def self.create(stop_areas)
          return nil if stop_areas.any?(&:referent?)
          new stop_areas
        end

        def initialize(stop_areas = [])
          @stop_areas = stop_areas
        end

        attr_reader :stop_areas, :stop_area_provider

        def name
          stop_areas.map(&:name).sort_by(&:length).last
        end

        def centroid
          Geo::Position.centroid(stop_areas)
        end

        def compass_bearing
          stop_areas.sum(&:compass_bearing) / stop_areas.count
        end

        def area_types
          stop_areas.map(&:area_type).uniq
        end

        def area_type
          area_types.first if area_types.one?
        end

        def attributes
          {
            name: name,
            latitude: centroid.latitude,
            longitude: centroid.longitude,
            compass_bearing: compass_bearing,
            is_referent: true,
            area_type: area_type
          }
        end
      end
    end
  end
end
