class Export::GTFS < Export::Base
  after_commit :launch_worker, :on => :create

  option :duration, required: true, type: :integer, default_value: 200

  def initialize
    super
    @stop_area_stop_hash = {}
    @line_route_hash = {}
    @time_table_periods_hash = {}
    @vehicule_journey_service_trip_hash = {}
  end

  def launch_worker
    GTFSExportWorker.perform_async(id)
  end

  def zip_file_name
    "chouette-its-#{Time.now.to_i}"
  end

  def date_range
    @date_range ||= Time.now.to_date..self.duration.to_i.days.from_now.to_date
  end

  def export
    referential.switch

    @date_range = Time.now.to_date..self.duration.to_i.days.from_now.to_date

    @journeys = Chouette::VehicleJourney.with_matching_timetable (@date_range)

    if @journeys.count == 0
      self.update status: :successful
      vals = {}
      vals[:criticity] = :info
      vals[:message_key] = :no_matching_journey
      self.messages.create vals
      return
    end

    tmp_dir = Dir.mktmpdir
    export_to_dir tmp_dir
  end

  def export_to_dir(directory)
    GTFS::Target.open(File.join(directory, "#{zip_file_name}.zip")) do |target|
      export_companies_to target
      export_stop_areas_to target
      export_lines_to target
      # Export Calendar & Calendar_dates
      export_time_tables_to target
      # Export Trips
      export_vehicle_journeys_to target
      # Export stop_times.txt
      export_vehicle_journey_at_stops_to target
      # Export files fare_rules, fare_attributes, shapes, frequencies, transfers
      # and feed_info aren't yet implemented as import nor export features from
      # the chouette model
    end
  end

  def export_companies_to(target)
    company_ids = @journeys.pluck :company_id
    company_ids += @journeys.joins(route: :line).pluck :"lines.company_id"
    Chouette::Company.where(id: company_ids.uniq).order('name').each do |company|
      target.agencies << {
        id: (company.registration_number.blank? ? company.id : company.registration_number),
        name: company.name,
        url: company.url,
        timezone: company.time_zone,
        phone: company.phone,
        email: company.email
        #lang: TO DO
        #fare_url: TO DO
      }
    end
  end

  def export_stop_areas_to(target)
    stops = Chouette::StopArea.where(id: @journeys.joins(route: :stop_points).pluck(:"stop_points.stop_area_id").uniq).order('parent_id ASC NULLS FIRST')
    results = export_stop_areas_recursively(stops)
    results.each do |stop_area|
      stop_id = stop_area.registration_number.presence || stop_area.id
      target.stops << {
        id: stop_id,
        name: stop_area.name,
        location_type: stop_area.area_type == 'zdlp' ? 1 : 0,
        parent_station: ((stop_area.parent.registration_number.presence || stop_area.parent.id) if stop_area.parent),
        lat: stop_area.latitude,
        lon: stop_area.longitude,
        desc: stop_area.comment,
        url: stop_area.url,
        timezone: stop_area.time_zone
        #code: TO DO
        #wheelchair_boarding: TO DO wheelchair_boarding <=> mobility_restricted_suitability ?
      }
    end
  end

  def export_stop_areas_recursively(stop_areas)
    stop_areas_array_result = []
    stop_areas_array_parents = []

    stop_areas.each do |stop_area|
      stop_id = stop_area.registration_number.presence || stop_area.id
      if (!@stop_area_stop_hash[stop_area.id])
        stop_areas_array_result << stop_area
        @stop_area_stop_hash[stop_area.id] = stop_id
        if (stop_area.parent && !@stop_area_stop_hash[stop_area.parent.id])
          stop_areas_array_parents<<stop_area.parent
        end
      end
    end
    if (stop_areas_array_parents.any?)
      export_stop_areas_recursively((stop_areas_array_parents)).concat stop_areas_array_result
    else
      stop_areas_array_result
    end
  end

  def export_lines_to(target)
    line_ids = @journeys.joins(:route).pluck(:line_id).uniq
    Chouette::Line.where(id: line_ids).each do |line|
      route_id = line.registration_number.presence || line.id
      target.routes << {
        id: route_id,
        agency_id: line.company.registration_number,
        long_name: line.published_name,
        short_name: line.number,
        type: line.gtfs_type,
        desc: line.comment,
        url: line.url
        #color: TO DO
        #text_color: TO DO
      }
      @line_route_hash[line.id] = route_id
    end
  end

  # Export Calendar & Calendar_dates
  def export_time_tables_to(target)
    date_range
    vehicule_journey_ids = @journeys.pluck :id
    Chouette::TimeTable.including_vehicle_journeys_within_date_range(vehicule_journey_ids, @date_range).each do |time_table|
      time_table_dates = time_table.dates.to_a

      # TO DO -> different timetable can reference the same period object. To prevent an overwhelming number of export entries
      # one should filter each period to check if it hasn't been already exported
      # actually, an already exported period can be referenced by other time_table_dates/calendar_dates, so we have no choice but to create a new calendar entry for each period
      time_table.periods.each do |period|
        # For each time_table, export periods included within the date range
        unless (period.period_end<@date_range.begin||period.period_start>@date_range.end)
          service_id = period.id
          target.calendars << {
            service_id: service_id,
            start_date: period.period_start.strftime('%Y%m%d'),
            end_date: period.period_end.strftime('%Y%m%d'),
            monday: time_table.monday ? 1:0,
            tuesday: time_table.tuesday ? 1:0,
            wednesday: time_table.wednesday ? 1:0,
            thursday: time_table.thursday ? 1:0,
            friday: time_table.friday ? 1:0,
            saturday: time_table.saturday ? 1:0,
            sunday: time_table.sunday ? 1:0
          }

          # Add excluded calendar dates within current period, or included dates within
          # specified date range (in that case attached to the first period/calendar entry)
          time_table_dates.delete_if do |time_table_date|
            if ((!time_table_date.in_out && time_table_date.date >= period.period_start && time_table_date.date <= period.period_end) ||
              (time_table_date.in_out && time_table_date.date >= @date_range.begin && time_table_date.date <= @date_range.end))
              target.calendar_dates << {
                service_id: service_id,
                date: time_table_date.date.strftime('%Y%m%d'),
                exception_type: time_table_date.in_out ? 1 : 2
              }
              true
            end
          end

          # Store the GTFS service_id corresponding to each time_table
          # initialize value
          @time_table_periods_hash[time_table.id] ||= []
          @time_table_periods_hash[time_table.id] << service_id
        end
      end
    end
  end

  def export_vehicle_journeys_to(target)
    c = 0
    @journeys.each do |vehicle_journey|
      # fetches the route_id stored in the routes_lines_hash variable
      route_id = @line_route_hash[vehicle_journey.route.line.id]
      # each entry in trips.txt corresponds to a kind of composite key made of both service_id and route_id
      vehicle_journey.time_tables.each do |time_table|
        @time_table_periods_hash[time_table.id].each do |service_id|
          c += 1
          trip_id = "trip_#{c}"
          target.trips << {
            route_id: route_id,
            service_id:  service_id,
            id: trip_id,
            #headsign: TO DO + store that field at import
            #short_name: TO DO + store that field at import
            direction_id: ((vehicle_journey.route.wayback == 'outbound' ? 0 : 1) if vehicle_journey.route.wayback.present?),
            #block_id: TO DO
            #shape_id: TO DO
            #wheelchair_accessible: TO DO
            #bikes_allowed: TO DO
          }
          @vehicule_journey_service_trip_hash[vehicle_journey.id] ||= []
          @vehicule_journey_service_trip_hash[vehicle_journey.id] << trip_id
        end
      end
    end
  end

  def export_vehicle_journey_at_stops_to(target)
    @journeys.each do |vehicle_journey|
      vehicle_journey.vehicle_journey_at_stops.each do |vehicle_journey_at_stop|
        @vehicule_journey_service_trip_hash[vehicle_journey.id].each do |trip_id|
          vehicle_journey_at_stop.departure_time
          target.stop_times << {
            trip_id: trip_id,
            arrival_time: GTFS::Time.format_datetime(vehicle_journey_at_stop.arrival_time, vehicle_journey_at_stop.arrival_day_offset),
            departure_time: GTFS::Time.format_datetime(vehicle_journey_at_stop.departure_time, vehicle_journey_at_stop.departure_day_offset),
            stop_id: @stop_area_stop_hash[vehicle_journey_at_stop.stop_point.id],
            stop_sequence: vehicle_journey_at_stop.stop_point.position # NOT SURE TO DO,
            # stop_headsign: TO STORE IN IMPORT,
            # pickup_type: TO STORE IN IMPORT,
            # pickup_type: TO STORE IN IMPORT,
            #shape_dist_traveled: TO STORE IN IMPORT,
            #timepoint: TO STORE IN IMPORT,
          }
        end
      end
    end
  end
end
