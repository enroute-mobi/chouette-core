module Chouette
  class ChecksumUpdater

    def initialize(referential, scope: nil)
      @referential = referential

      scope ||= referential
      @scope = scope
    end

    attr_reader :referential, :scope

    ALL = %i{routes journey_patterns vehicle_journeys time_tables}
    def update(only: [], except: [])
      targets = (only.presence || ALL) - except
      targets.delete_if { |target| !scope.respond_to? target  }

      targets.each { |target| send target }
    end

    def routes
      measure "routes" do
        update_in_batches scope.routes.select(:id, :name, :published_name, :wayback).includes(:stop_points, :routing_constraint_zones)
      end
    end

    def journey_patterns
      measure "journey_patterns" do
        update_in_batches scope.journey_patterns.select(:id, :custom_field_values, :name, :published_name, :registration_number, :costs).includes(:stop_points)
      end
    end

    def vehicle_journeys
      measure "vehicle_journeys" do
        update_in_batches scope.vehicle_journey_at_stops.select(:id, :departure_time, :arrival_time, :departure_day_offset, :arrival_day_offset, :stop_area_id)
        update_in_batches scope.vehicle_journeys.select(:id, :custom_field_values, :published_journey_name, :published_journey_identifier, :ignored_routing_contraint_zone_ids, :ignored_stop_area_routing_constraint_ids, :company_id, :line_notice_ids).includes(:company_light, :footnotes, :vehicle_journey_at_stops, :purchase_windows)
      end
    end

    def time_tables
      measure "time_tables" do
        update_in_batches scope.time_table_dates.select(:date, :in_out)
        update_in_batches scope.time_table_periods.select(:period_start, :period_end)
        update_in_batches scope.time_tables.select(:int_day_types).includes(:dates, :periods)
      end
    end

    protected

    def measure(name, &block)
      Chouette::Benchmark.measure "checksum_updater/#{name}", id: referential.id, &block
    end

    def workgroup
      @workgroup ||= referential.workbench.workgroup
    end

    def update_in_batches(collection)
      CustomFieldsSupport.within_workgroup(workgroup) do
        referential.switch do
          Chouette::ChecksumManager.update_checkum_in_batches(collection, referential)
        end
      end
    end

  end
end
