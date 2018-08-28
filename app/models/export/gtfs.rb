class Export::Gtfs < Export::Base
  include LocalExportSupport

  option :duration, required: true, type: :integer, default_value: 200

  @skip_empty_exports = true

  def worker_class
    GTFSExportWorker
  end

  def zip_file_name
    @zip_file_name ||= "chouette-its-#{Time.now.to_i}"
  end

  def stop_area_stop_hash
    @stop_area_stop_hash ||= {}
  end

  def journey_periods_hash
    @journey_periods_hash ||= {}
  end

  def vehicule_journey_service_trip_hash
    @vehicule_journey_service_trip_hash ||= {}
  end

  def line_company_hash
    @line_company_hash ||= {}
  end

  def vehicle_journey_time_zone_hash
    @vehicle_journey_time_zone_hash ||= {}
  end

  def agency_id company
    (company.registration_number.presence || company.object_id) if company
  end

  def route_id line
    line.registration_number.presence || line.object_id
  end

  def stop_id stop_area
    stop_area.registration_number.presence || stop_area.object_id
  end

  def generate_export_file
    tmp_dir = Dir.mktmpdir
    export_to_dir tmp_dir
    File.open File.join(tmp_dir, "#{zip_file_name}.zip")
  end

  def gtfs_line_type line
    case line.transport_mode
    when 'rail'
      '2'
    else
      '3'
    end
  end

  def export_to_dir(directory)
    GTFS::Target.open(File.join(directory, "#{zip_file_name}.zip")) do |target|
      export_companies_to target
      notify_progress 1.0/6
      export_stop_areas_to target
      notify_progress 2.0/6
      export_lines_to target
      notify_progress 3.0/6
      # Export Calendar & Calendar_dates
      export_time_tables_to target
      notify_progress 4.0/6
      # Export Trips
      export_vehicle_journeys_to target
      notify_progress 5.0/6
      # Export stop_times.txt
      export_vehicle_journey_at_stops_to target
      notify_progress 6.0/6
      # Export files fare_rules, fare_attributes, shapes, frequencies, transfers
      # and feed_info aren't yet implemented as import nor export features from
      # the chouette model
    end
  end

  def export_companies_to(target)
    company_ids = []
    journeys.each do |journey|
      company_id = journey.company_id.presence || journey.route.line.company_id.presence || "chouette_default"
      if company_id == "chouette_default"
        args = {
          criticity: :info,
          message_key: :no_company,
          message_attributes: {
            journey_name: journey.published_journey_name,
            line_name: journey.route.line.published_name
          }
        }
        self.messages.create args
      end

      company_ids << company_id
      line_company_hash[journey.route.line_id] = company_id
      vehicle_journey_time_zone_hash[journey.id] = company_id == "chouette_default" ? "Etc/GMT" : company_id
    end
    company_ids.uniq!

    Chouette::Company.where(id: company_ids-["chouette_default"]).order('name').each do |company|
      if company.time_zone.present?
        time_zone = company.time_zone
      else
        time_zone = "Etc/GMT"
        args = {
          criticity: :info,
          message_key: :no_timezone,
          message_attributes: {
            company_name: company.name
          }
        }
        self.messages.create args
      end
      a_id = agency_id(company)

      target.agencies << {
        id: a_id,
        name: company.name,
        url: company.url,
        timezone: time_zone,
        phone: company.phone,
        email: company.email
        #lang: TO DO
        #fare_url: TO DO
      }

      line_company_hash.each {|k,v| line_company_hash[k] = a_id if v == company.id}
      vehicle_journey_time_zone_hash.each {|k,v| vehicle_journey_time_zone_hash[k] = time_zone if v == company.id}
    end

    if company_ids.include? "chouette_default"
      target.agencies << {
        id: "chouette_default",
        name: "Default Agency",
        timezone: "Etc/GMT",
      }
    end
  end

  def export_stop_areas_to(target)
    stops = Chouette::StopArea.where(id: journeys.joins(route: :stop_points).pluck(:"stop_points.stop_area_id").uniq).where(kind: :commercial).order('parent_id ASC NULLS FIRST')
    results = export_stop_areas_recursively(stops)
    results.each do |stop_area|
      target.stops << {
        id: stop_id(stop_area),
        name: stop_area.name,
        location_type: stop_area.area_type == 'zdlp' ? 1 : 0,
        parent_station: (stop_id(stop_area.parent) if stop_area.parent),
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
      if (!stop_area_stop_hash[stop_area.id])
        stop_areas_array_result << stop_area
        stop_area_stop_hash[stop_area.id] = stop_id(stop_area)
        if (stop_area.parent && !stop_area_stop_hash[stop_area.parent.id])
          stop_areas_array_parents << stop_area.parent
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
    line_ids = journeys.joins(:route).pluck(:line_id).uniq
    Chouette::Line.where(id: line_ids).each do |line|
      target.routes << {
        id: route_id(line),
        agency_id: line_company_hash[line.id],
        long_name: line.published_name,
        short_name: line.number,
        type: gtfs_line_type(line),
        desc: line.comment,
        url: line.url
        #color: TO DO
        #text_color: TO DO
      }
    end
  end

  # Export Calendar & Calendar_dates
  def export_time_tables_to(target)
    date_range
    start_progress = 3.0/6
    count = journeys.count
    journeys.each_with_index do |vehicle_journey, i|
      vehicle_journey.flattened_circulation_periods.select{|period| period.range & date_range}.each do |period|
        service_id = period.object_id
        target.calendars << {
          service_id: service_id,
          start_date: period.period_start.strftime('%Y%m%d'),
          end_date: period.period_end.strftime('%Y%m%d'),
          monday: period.monday ? 1:0,
          tuesday: period.tuesday ? 1:0,
          wednesday: period.wednesday ? 1:0,
          thursday: period.thursday ? 1:0,
          friday: period.friday ? 1:0,
          saturday: period.saturday ? 1:0,
          sunday: period.sunday ? 1:0
        }

        # TO MODIFY IF NEEDED : the method vehicle_journeys#flattened_circulation_periods casts any time_table_dates into a single day period/calendar.
        # Thus, for the moment, no time_table_dates / calendar_dates.txt 'll be exported.

        # time_table_dates.delete_if do |time_table_date|
        #   if ((!time_table_date.in_out && time_table_date.date >= period.period_start && time_table_date.date <= period.period_end) ||
        #     (time_table_date.in_out && time_table_date.date >= date_range.begin && time_table_date.date <= date_range.end))
        #     target.calendar_dates << {
        #       service_id: service_id,
        #       date: time_table_date.date.strftime('%Y%m%d'),
        #       exception_type: time_table_date.in_out ? 1 : 2
        #     }
        #     true
        #   end
        # end

        # Store the GTFS service_id corresponding to each time_table
        # initialize value
        journey_periods_hash[vehicle_journey.id] ||= []
        journey_periods_hash[vehicle_journey.id] << service_id
      end
      notify_progress start_progress + i/6.0/count
    end
  end

  def export_vehicle_journeys_to(target)
    c = 0
    journeys.each do |vehicle_journey|
      # each entry in trips.txt corresponds to a kind of composite key made of both service_id and route_id
      journey_periods_hash[vehicle_journey.id].each do |service_id|
        c += 1
        trip_id = "trip_#{c}"
        target.trips << {
          route_id: route_id(vehicle_journey.route.line),
          service_id:  service_id,
          id: trip_id,
          #headsign: TO DO + store that field at import
          short_name: vehicle_journey.published_journey_name,
          direction_id: ((vehicle_journey.route.wayback == 'outbound' ? 0 : 1) if vehicle_journey.route.wayback.present?),
          #block_id: TO DO
          #shape_id: TO DO
          #wheelchair_accessible: TO DO
          #bikes_allowed: TO DO
        }
        vehicule_journey_service_trip_hash[vehicle_journey.id] ||= []
        vehicule_journey_service_trip_hash[vehicle_journey.id] << trip_id
      end
    end
  end

  def export_vehicle_journey_at_stops_to(target)
    journeys.each do |vehicle_journey|
      vj_timezone = vehicle_journey_time_zone_hash[vehicle_journey.id]

      vehicle_journey.vehicle_journey_at_stops.each do |vj_at_stop|
        next if !vj_at_stop.stop_point.stop_area.commercial?

        vehicule_journey_service_trip_hash[vehicle_journey.id].each do |trip_id|

          arrival_time = GTFS::Time.format_datetime(vj_at_stop.arrival_time, vj_at_stop.arrival_day_offset, vj_timezone) if vj_at_stop.arrival_time
          departure_time = GTFS::Time.format_datetime(vj_at_stop.departure_time, vj_at_stop.departure_day_offset, vj_timezone) if vj_at_stop.departure_time

          target.stop_times << {
            trip_id: trip_id,
            arrival_time: arrival_time,
            departure_time: departure_time,
            stop_id: stop_area_stop_hash[vj_at_stop.stop_point.stop_area_id],
            stop_sequence: vj_at_stop.stop_point.position # NOT SURE TO DO
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
