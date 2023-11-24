class ReferentialCopy
  extend Enumerize
  include ReferentialCopyHelpers
  include Measurable

  attr_accessor :source, :target, :source_priority, :status, :last_error, :skip_metadatas
  alias skip_metadatas? skip_metadatas

  attr_writer :lines

  enumerize :status, in: %w[new pending successful failed running], default: :new

  def initialize(options={})
    options.each { |k,v| send "#{k}=", v }
  end

  def referential_inserter
    @referential_inserter ||= ReferentialInserter.new(target) do |config|
      config.add IdMapInserter, strict: true
      config.add CopyInserter
    end
  end

  def copy(raise_error: false)
    measure "copy", source: source.id, target: target.id do
      CustomFieldsSupport.within_workgroup(workgroup) do
        copy_resource(:metadatas) unless skip_metadatas?
        source.switch do
          lines.includes(:footnotes, :routes).find_each do |line|
            @new_routes = nil
            copy_resource(:footnotes, line)
            copy_resource(:routes, line)
          end
        end
        @status = :successful
      end

      copy_with_inserters
    end
  rescue SaveError => e
    Chouette::Safe.capture "ReferentialCopy failed", e
    failed! e.message
    raise if raise_error
  end

  def copy_with_inserters
    source.switch do
      vehicle_journeys = source.vehicle_journeys.joins(:route).where("routes.line_id" => lines)
      time_tables = source.time_tables.joins(:vehicle_journeys).where('vehicle_journeys.id' => vehicle_journeys).distinct

      measure "time_tables" do
        time_tables.find_each do |time_table|
          referential_inserter.time_tables << time_table
        end

        measure "dates" do
          source.time_table_dates.where(time_table: time_tables).find_each do |time_table_date|
            referential_inserter.time_table_dates << time_table_date
          end
        end

        measure "periods" do
          source.time_table_periods.where(time_table: time_tables).find_each do |time_table_period|
            referential_inserter.time_table_periods << time_table_period
          end
        end
      end

      measure "vehicle_journeys" do
        CustomFieldsSupport.within_workgroup(workgroup) do
          vehicle_journeys.find_each do |vehicle_journey|
            referential_inserter.vehicle_journeys << vehicle_journey
          end
        end
      end

      measure "vehicle_journey_at_stops" do
        vehicle_journey_at_stops = source.vehicle_journey_at_stops.where(vehicle_journey: vehicle_journeys)

        vehicle_journey_at_stops.find_each_light do |light_vehicle_journey_at_stop|
          referential_inserter.vehicle_journey_at_stops << light_vehicle_journey_at_stop
        end
      end

      measure "time_tables_vehicle_journeys" do
        time_tables_vehicle_journeys = Chouette::TimeTablesVehicleJourney.where(vehicle_journey: vehicle_journeys)

        time_tables_vehicle_journeys.find_each_without_primary_key do |model|
          referential_inserter.vehicle_journey_time_table_relationships << model
        end
      end

      measure "referential_codes" do
        referential_codes = source.codes.where(resource: vehicle_journeys)

        referential_codes.find_each do |code|
          referential_inserter.codes << code
        end
      end
    end

    referential_inserter.flush
  end

  def copy!
    copy raise_error: true
  end

  def copy_resource(resource_name, *params)
    measure_attributes = {}
    unless params.blank?
      line = params.first
      measure_attributes[:line] = line&.id
    end

    measure "copy_#{resource_name}", measure_attributes do
      send "copy_#{resource_name}", *params
    end
  end

  private

  def lines
    @lines ||= source.lines
  end

  def workgroup
    @workgroup ||= target.workgroup
  end

  # METADATAS

  def copy_metadatas
    source.metadatas.find_each do |metadata|
      candidate = target.metadatas.with_lines(metadata.line_ids).find { |m| m.periodes == metadata.periodes }
      candidate ||= target.metadatas.build(line_ids: metadata.line_ids, periodes: metadata.periodes, referential_source: source, created_at: metadata.created_at, updated_at: metadata.created_at)
      candidate.priority = source_priority if source_priority
      candidate.flagged_urgent_at = metadata.flagged_urgent_at if metadata.urgent?
      controlled_save! candidate
    end
  end

  # TIMETABLES

  class TimeTableScope

    def initialize(target, table_ids)
      @target, @table_ids = target, table_ids
    end

    attr_reader :target, :table_ids

    def target_time_tables
      @target_time_tables ||= target.time_tables.where(id: table_ids)
    end

    def time_tables
      target_time_tables.includes(:dates, :periods)
    end

    def time_table_dates
      target.time_table_dates.where(time_table_id: target_time_tables)
    end

    def time_table_periods
      target.time_table_periods.where(time_table_id: target_time_tables)
    end

  end

  # FOOTNOTES

  def copy_footnotes line
    line.footnotes.find_each do |footnote|
      copy_item_to_target_collection footnote, line.footnotes
    end
  end

  # ROUTES

  def copy_routes line
    line.routes.find_each(&method(:copy_route))
  end

  def copy_route route
    line = route.line
    attributes = clean_attributes_for_copy route
    opposite_route = route.opposite_route

    target.switch do
      new_route = line.routes.build attributes

      copy_collection route, new_route, :stop_points

      new_route.opposite_route_id = matching_id(opposite_route)

      controlled_save! new_route
      @new_routes ||= []
      @new_routes << new_route.id

      record_match(route, new_route)

      # we copy the journey_patterns
      copy_collection route, new_route, :journey_patterns do |journey_pattern, new_journey_pattern|
        new_journey_pattern.arrival_stop_point_id = nil
        new_journey_pattern.departure_stop_point_id = nil

        controlled_save! new_journey_pattern
        stop_point_ids = source.switch(verbose: false) do
          journey_pattern.stop_points.select(:id).map{|sp| matching_id(sp)}
        end

        if stop_point_ids.present?
          target.switch do
            Chouette::JourneyPatternsStopPoint.bulk_insert do |worker|
              stop_point_ids.each do |id|
                worker.add journey_pattern_id: new_journey_pattern.id, stop_point_id: id
              end
            end

            new_journey_pattern.stop_points.reload
            new_journey_pattern.shortcuts_update_for_add(new_journey_pattern.stop_points.last)
          end
        end

        sql = "INSERT INTO \"#{target.slug}\".service_counts (journey_pattern_id,route_id,line_id,date,count) "
        sql << "(SELECT '#{new_journey_pattern.id}','#{new_route.id}',line_id,date,count FROM \"#{source.slug}\".service_counts WHERE service_counts.journey_pattern_id = '#{journey_pattern.id}' )"
        ActiveRecord::Base.connection.execute sql
      end

      # we copy the routing_constraint_zones
      copy_collection route, new_route, :routing_constraint_zones do |rcz, new_rcz|
        new_rcz.stop_point_ids = []
        retrieve_collection_with_mapping rcz, new_rcz, new_route.stop_points, :stop_points
      end
    end
    clean_matches Chouette::StopPoint, Chouette::JourneyPattern, Chouette::VehicleJourney, Chouette::RoutingConstraintZone
  end
end
