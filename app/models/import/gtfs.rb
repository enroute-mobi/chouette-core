class Import::Gtfs < Import::Base
  after_commit :launch_worker, :on => :create

  def launch_worker
    GtfsImportWorker.perform_async id
  end

  def import
    update status: 'running', started_at: Time.now

    import_without_status
    update status: 'successful', ended_at: Time.now
    referential&.ready!
  rescue Exception => e
    update status: 'failed', ended_at: Time.now
    Rails.logger.error "Error in GTFS import: #{e} #{e.backtrace.join('\n')}"
    referential&.failed!
  ensure
    notify_parent
  end

  def self.accept_file?(file)
    Zip::File.open(file) do |zip_file|
      zip_file.glob('agency.txt').size == 1
    end
  rescue Exception => e
    Rails.logger.debug "Error in testing GTFS file: #{e}"
    return false
  end

  def create_referential
    self.referential ||= Referential.create!(
      name: "GTFS Import",
      organisation_id: workbench.organisation_id,
      workbench_id: workbench.id,
      metadatas: [referential_metadata]
    )
  end

  def referential_metadata
    registration_numbers = source.routes.map(&:id)
    line_ids = line_referential.lines.where(registration_number: registration_numbers).pluck(:id)

    start_dates, end_dates = source.calendars.map { |c| [c.start_date, c.end_date ] }.transpose
    excluded_dates = source.calendar_dates.select { |d| d.exception_type == "2" }.map(&:date)

    min_date = Date.parse (start_dates + [excluded_dates.min]).compact.min
    max_date = Date.parse (end_dates + [excluded_dates.max]).compact.max

    ReferentialMetadata.new line_ids: line_ids, periodes: [min_date..max_date]
  end

  attr_accessor :local_file
  def local_file
    @local_file ||= download_local_file
  end

  attr_accessor :download_host
  def download_host
    @download_host ||= Rails.application.config.rails_host
  end

  def local_temp_directory
    @local_temp_directory ||=
      begin
        directory = Rails.application.config.try(:import_temporary_directory) || Rails.root.join('tmp', 'imports')
        FileUtils.mkdir_p directory
        directory
      end
  end

  def local_temp_file(&block)
    Tempfile.open("chouette-import", local_temp_directory) do |file|
      file.binmode
      yield file
    end
  end

  def download_path
    Rails.application.routes.url_helpers.download_workbench_import_path(workbench, id, token: token_download)
  end

  def download_uri
    @download_uri ||=
      begin
        host = download_host
        host = "http://#{host}" unless host =~ %r{https?://}
        URI.join(host, download_path)
      end
  end

  def download_local_file
    local_temp_file do |file|
      begin
        Net::HTTP.start(download_uri.host, download_uri.port) do |http|
          http.request_get(download_uri.request_uri) do |response|
            response.read_body do |segment|
              file.write segment
            end
          end
        end
      ensure
        file.close
      end

      file.path
    end
  end

  def source
    @source ||= ::GTFS::Source.build local_file
  end

  delegate :line_referential, :stop_area_referential, to: :workbench

  def prepare_referential
    import_agencies
    import_stops
    import_routes

    create_referential
    referential.switch
  end

  def import_without_status
    prepare_referential

    import_calendars
    import_trips
    import_stop_times
  end

  def import_agencies
    Chouette::Company.transaction do
      source.agencies.each do |agency|
        company = line_referential.companies.find_or_initialize_by(registration_number: agency.id)
        company.attributes = { name: agency.name }

        save_model company
      end
    end
  end

  def import_stops
    Chouette::StopArea.transaction do
      source.stops.each do |stop|
        stop_area = stop_area_referential.stop_areas.find_or_initialize_by(registration_number: stop.id)

        stop_area.name = stop.name
        stop_area.area_type = stop.location_type == "1" ? "zdlp" : "zdep"
        stop_area.parent = stop_area_referential.stop_areas.find_by!(registration_number: stop.parent_station) if stop.parent_station.present?
        stop_area.latitude, stop_area.longitude = stop.lat, stop.lon
        stop_area.kind = "commercial"

        # TODO correct default timezone

        save_model stop_area
      end
    end
  end

  def import_routes
    Chouette::Line.transaction do
      source.routes.each do |route|
        line = line_referential.lines.find_or_initialize_by(registration_number: route.id)
        line.name = route.long_name.presence || route.short_name
        line.number = route.short_name
        line.published_name = route.long_name

        line.company = line_referential.companies.find_by(registration_number: route.agency_id) if route.agency_id.present?

        # TODO transport mode

        line.comment = route.desc

        # TODO colors

        line.url = route.url

        save_model line
      end
    end
  end

  def vehicle_journey_by_trip_id
    @vehicle_journey_by_trip_id ||= {}
  end

  def import_trips
    source.trips.each_slice(100) do |slice|
      slice.each do |trip|
        Chouette::Route.transaction do
          line = line_referential.lines.find_by registration_number: trip.route_id

          route = referential.routes.build line: line
          route.wayback = (trip.direction_id == "0" ? :outbound : :inbound)
          # TODO better name ?
          name = route.published_name = trip.short_name.presence || trip.headsign.presence || route.wayback.to_s.capitalize
          route.name = name
          save_model route

          journey_pattern = route.journey_patterns.build name: name
          save_model journey_pattern

          vehicle_journey = journey_pattern.vehicle_journeys.build route: route
          vehicle_journey.published_journey_name = trip.headsign.presence || trip.id
          save_model vehicle_journey

          time_table = referential.time_tables.find_by(id: time_tables_by_service_id[trip.service_id]) if time_tables_by_service_id[trip.service_id]
          if time_table
            vehicle_journey.time_tables << time_table
          else
            messages.create! criticity: "warning", message_key: "gtfs.trips.unkown_service_id", message_attributes: {service_id: trip.service_id}
          end

          vehicle_journey_by_trip_id[trip.id] = vehicle_journey.id
        end
      end
    end
  end

  def import_stop_times
    source.stop_times.group_by(&:trip_id).each_slice(50) do |slice|
      slice.each do |trip_id, stop_times|
        Chouette::VehicleJourneyAtStop.transaction do
          vehicle_journey = referential.vehicle_journeys.find vehicle_journey_by_trip_id[trip_id]
          journey_pattern = vehicle_journey.journey_pattern
          route = journey_pattern.route

          stop_times.sort_by! { |s| s.stop_sequence.to_i }

          stop_times.each do |stop_time|
            stop_area = stop_area_referential.stop_areas.find_by(registration_number: stop_time.stop_id)

            stop_point = route.stop_points.build stop_area: stop_area
            save_model stop_point

            journey_pattern.stop_points << stop_point

            # JourneyPattern#vjas_add creates automaticaly VehicleJourneyAtStop
            vehicle_journey_at_stop = journey_pattern.vehicle_journey_at_stops.find_by(stop_point_id: stop_point.id)

            departure_time = GTFS::Time.parse(stop_time.departure_time)
            arrival_time = GTFS::Time.parse(stop_time.arrival_time)

            vehicle_journey_at_stop.departure_time = departure_time.time
            vehicle_journey_at_stop.arrival_time = arrival_time.time
            vehicle_journey_at_stop.departure_day_offset = departure_time.day_offset
            vehicle_journey_at_stop.arrival_day_offset = arrival_time.day_offset

            # TODO offset

            save_model vehicle_journey_at_stop
          end
        end
      end
    end
  end

  def time_tables_by_service_id
    @time_tables_by_service_id ||= {}
  end

  def import_calendars
    source.calendars.each_slice(500) do |slice|
      Chouette::TimeTable.transaction do
        slice.each do |calendar|
          time_table = referential.time_tables.build comment: "Calendar #{calendar.service_id}"
          Chouette::TimeTable.all_days.each do |day|
            time_table.send("#{day}=", calendar.send(day))
          end
          time_table.periods.build period_start: calendar.start_date, period_end: calendar.end_date

          save_model time_table

          time_tables_by_service_id[calendar.service_id] = time_table.id
        end
      end
    end
  end

  def import_calendar_dates
    source.calendar_dates.each_slice(500) do |slice|
      Chouette::TimeTable.transaction do
        slice.each do |calendar_date|
          time_table = referential.time_tables.find time_tables_by_service_id[calendar_date.service_id]
          date = time_table.dates.build date: Date.parse(calendar_date.date), in_out: calendar_date.exception_type == "1"

          save_model date
        end
      end
    end
  end

  def save_model(model)
    unless model.save
      Rails.logger.info "Can't save #{model.class.name} : #{model.errors.inspect}"
      raise ActiveRecord::RecordNotSaved.new("Invalid #{model.class.name} : #{model.errors.inspect}")
    end
    Rails.logger.debug "Created #{model.inspect}"
  end

  def notify_parent
    return unless parent.present?
    return if notified_parent_at
    parent.child_change
    update_column :notified_parent_at, Time.now
  end

end
