module Chouette
  class ChecksumUpdater

    def initialize(referential, scope: nil, updater: nil)
      @referential = referential

      scope ||= referential
      @scope = scope
      @updater = updater
    end

    attr_reader :referential, :scope

    ALL = %i{routes journey_patterns vehicle_journeys time_tables}
    def update(only: [], except: [])
      Rails.logger.debug "Compute checksums in referential #{referential.id}"
      targets = (only.presence || ALL) - except
      targets.delete_if { |target| !scope.respond_to? target  }

      targets.each { |target| send target }
    end

    def routes
      measure "routes" do
        update_in_batches scope.routing_constraint_zones.select(:id, :stop_point_ids)
        update_in_batches scope.routes.select(:id, :name, :published_name, :wayback).includes(:stop_points, :routing_constraint_zones)
      end
    end

    def journey_patterns
      measure "journey_patterns" do
        update_in_batches scope.journey_patterns.select(:id, :custom_field_values, :name, :published_name, :registration_number, :costs, :shape_id).includes(:stop_points)
      end
    end

    def vehicle_journeys
      measure "vehicle_journeys" do
        update_in_batches scope.vehicle_journey_at_stops.select(:id, :departure_time, :arrival_time, :departure_day_offset, :arrival_day_offset, :stop_area_id)
        update_in_batches(
          scope
            .vehicle_journeys
            .select(
              :id, :custom_field_values, :published_journey_name, :published_journey_identifier,
              :company_id, :line_notice_ids, :service_facility_set_ids, :accessibility_assessment_id
            ).includes(:company_light, :footnotes, :vehicle_journey_at_stops)
        )
      end
    end

    def time_tables
      measure "time_tables" do
        update_in_batches scope.time_table_dates.select(:id, :date, :in_out)
        update_in_batches scope.time_table_periods.select(:id, :period_start, :period_end)
        update_in_batches scope.time_tables.select(:id, :int_day_types).includes(:dates, :periods)
      end
    end

    protected

    def updater
      @updater ||= Updater.new(self)
    end

    def measure(name, &block)
      Chouette::Benchmark.measure "checksum_updater/#{name}", id: referential.id, &block
    end

    delegate :workgroup, to: :referential

    def update_in_batches(collection)
      updater.call(collection)
    end

    class Updater
      def initialize(context)
        @context = context
      end
      attr_reader :context
      delegate :workgroup, :referential, to: :context

      def call(collection)
        CustomFieldsSupport.within_workgroup(workgroup) do
          referential.switch do
            Chouette::ChecksumManager.update_checkum_in_batches(collection, referential)
          end
        end
      end
    end

  end
end
