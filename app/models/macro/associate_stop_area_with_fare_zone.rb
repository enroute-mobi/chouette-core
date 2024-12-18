# frozen_string_literal: true

module Macro
  class AssociateStopAreaWithFareZone < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_attribute

        validates :target_attribute, :model_attribute, presence: true
      end

      def model_attribute
        candidate_target_attributes.find_by(model_name: 'StopArea', name: target_attribute)
      end

      def candidate_target_attributes
        Chouette::ModelAttribute.collection do
          select Chouette::StopArea, :country_code
          select Chouette::StopArea, :zip_code
          select Chouette::StopArea, :city_name
          select Chouette::StopArea, :postal_region
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        candidate_stop_area_zones.each do |stop_area_zone_attributes|
          stop_area_zone = Fare::StopAreaZone.create(
            stop_area_zone_attributes.except('stop_area_name', 'fare_zone_name')
          )

          create_message(stop_area_zone, stop_area_zone_attributes)
        end
      end

      def candidate_stop_area_zones
        PostgreSQLCursor::Cursor.new(Query.new(scope, model_attribute.name).query)
      end

      def create_message(stop_area_zone, stop_area_zone_attributes)
        attributes = {
          message_attributes: {
            stop_area_name: stop_area_zone_attributes['stop_area_name'],
            fare_zone_name: stop_area_zone_attributes['fare_zone_name']
          },
          source_id: stop_area_zone.stop_area_id,
          source_type: '::Chouette::StopArea'
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless stop_area_zone.valid?

        macro_messages.create!(attributes)
      end

      class Query
        def initialize(scope, geographic_attribute)
          @scope = scope
          @geographic_attribute = geographic_attribute
        end
        attr_reader :scope, :geographic_attribute

        def query
          <<-SQL
            SELECT
              A.stop_area_id, A.stop_area_name,
              A.fare_zone_id, A.fare_zone_name
            FROM
              (#{stop_areas_fare_zone_geographic_references}) A
            LEFT JOIN
              public.fare_stop_areas_zones B
            ON A.stop_area_id = B.stop_area_id
            AND A.fare_zone_id = B.fare_zone_id
            WHERE B.id IS NULL
          SQL
        end

        def stop_areas_fare_zone_geographic_references
          <<-SQL
            SELECT
              s.id AS stop_area_id,
              s.name AS stop_area_name,
              f.id AS fare_zone_id,
              f.name AS fare_zone_name
            FROM
              (#{stop_areas.to_sql}) AS s
            INNER JOIN
              (#{fare_zone_geographic_references.to_sql}) AS f
            ON s.#{geographic_attribute} = f.short_name
          SQL
        end

        def fare_zone_geographic_references
          fare_zones
            .joins(:fare_geographic_references)
            .select('fare_zones.*', 'fare_geographic_references.short_name AS short_name')
        end

        def stop_areas
          @stop_areas ||= scope.stop_areas
        end

        def fare_zones
          @fare_zones ||= scope.fare_zones
        end
      end
    end
  end
end
