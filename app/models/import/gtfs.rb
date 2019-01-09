class Import::Gtfs < Import::Base
  after_commit :launch_worker, on: :create

  after_commit :update_main_resource_status, on:  [:create, :update]

  def launch_worker
    GtfsImportWorker.perform_async_or_fail(self)
  end

  def main_resource
    @resource ||= parent.resources.find_or_create_by(name: referential_name, resource_type: 'referential', reference: self.name) if parent
  end

  def update_main_resource_status
    main_resource.update_status_from_importer status
    true
  end

  def create_resource name
    resources.find_or_initialize_by(name: name, resource_type: 'file', reference: name)
  end

  def next_step
    main_resource&.next_step
  end

  def create_message args, opts={}
    resource = opts[:resource] || main_resource || self
    resource.messages.build args
    return unless opts[:commit]

    begin
      resource.save!
    rescue
      Rails.logger.error "Invalid resource: #{resource.errors.inspect}"
      Rails.logger.error "Last message: #{resource.messages.last.errors.inspect}"
      raise
    end
    resource.update_status_from_messages
  end

  def import
    update status: 'running', started_at: Time.now

    import_without_status
    @status ||= 'successful'
    update status: @status, ended_at: Time.now
    referential&.active!
  rescue => e
    update status: 'failed', ended_at: Time.now
    Rails.logger.error "Error in GTFS import: #{e} #{e.backtrace.join('\n')}"
    if (referential && overlapped_referential_ids = referential.overlapped_referential_ids).present?
      overlapped = Referential.find overlapped_referential_ids.last
      create_message(
        criticity: :error,
        message_key: "referential_creation_overlapping_existing_referential",
        message_attributes: {
          referential_name: referential.name,
          overlapped_name: overlapped.name,
          overlapped_url:  Rails.application.routes.url_helpers.referential_path(overlapped)
        }
      )
    else
      create_message criticity: :error, message_key: :full_text, message_attributes: {text: e.message}
    end
    referential&.failed!
  ensure
    main_resource&.save
    save
    notify_parent
  end

  def self.accept_file?(file)
    Zip::File.open(file) do |zip_file|
      zip_file.glob('agency.txt').size == 1
    end
  rescue => e
    Rails.logger.debug "Error in testing GTFS file: #{e}"
    return false
  end

  def create_referential
    self.referential ||=  Referential.new(
      name: referential_name,
      organisation_id: workbench.organisation_id,
      workbench_id: workbench.id,
      metadatas: [referential_metadata]
    )
    begin
      self.referential.save!
    rescue => e
      Rails.logger.error "Unable to create referential: #{self.referential.errors.messages}"
      raise
    end
    main_resource.update referential: referential if main_resource
  end

  def referential_name
    name.presence || File.basename(local_file.to_s)
  end

  def referential_metadata
    registration_numbers = source.routes.map(&:id)
    line_ids = line_referential.lines.where(registration_number: registration_numbers).pluck(:id)

    start_dates, end_dates = source.calendars.map { |c| [c.start_date, c.end_date] }.transpose

    start_dates ||= []
    end_dates ||= []

    included_dates = []
    if source.entries.include?('calendar_dates.txt')
      included_dates = source.calendar_dates.select { |d| d.exception_type == "1" }.map(&:date)
    end

    min_date = Date.parse (start_dates + [included_dates.min]).compact.min
    min_date = [min_date, Date.current.beginning_of_year - PERIOD_EXTREME_VALUE].max

    max_date = Date.parse (end_dates + [included_dates.max]).compact.max
    max_date = [max_date, Date.current.end_of_year + PERIOD_EXTREME_VALUE].min

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
    @source ||= ::GTFS::Source.build local_file, strict: false
  end

  delegate :line_referential, :stop_area_referential, to: :workbench

  def import_resources(*resources)
    resources.each do |resource|
      Chouette::Benchmark.log "ImportGTFS import #{resource}" do
        send "import_#{resource}"
      end
    end
  end

  def prepare_referential
    import_resources :agencies, :stops, :routes

    create_referential
    referential.switch
  end

  def import_without_status
    prepare_referential
    referential.pending!

    import_resources :calendars, :calendar_dates
    import_resources :trips, :stop_times
  end

  def import_agencies
    create_resource(:agencies).each(source.agencies) do |agency, resource|
      company = line_referential.companies.find_or_initialize_by(registration_number: agency.id)
      company.attributes = { name: agency.name }
      company.url = agency.url
      company.time_zone = agency.timezone

      save_model company, resource: resource
    end
  end

  def import_stops
    sorted_stops = source.stops.sort_by { |s| s.parent_station ? 1 : 0 }
    create_resource(:stops).each(sorted_stops, slice: 100, transaction: true) do |stop, resource|
      stop_area = stop_area_referential.stop_areas.find_or_initialize_by(registration_number: stop.id)

      stop_area.name = stop.name
      stop_area.area_type = stop.location_type == '1' ? :zdlp : :zdep
      stop_area.latitude, stop_area.longitude = stop.lat, stop.lon
      stop_area.kind = :commercial
      stop_area.deleted_at = nil
      stop_area.confirmed_at = Time.now

      if stop.parent_station.present?
        if check_parent_is_valid_or_create_message(Chouette::StopArea, stop.parent_station, resource)
          stop_area.parent = find_stop_parent_or_create_message(stop.name, stop.parent_station, resource)
        end
      end

      # TODO correct default timezone

      save_model stop_area, resource: resource
    end
  end

  def import_routes
    create_resource(:routes).each(source.routes, transaction: true) do |route, resource|
      if route.agency_id.present?
        next unless check_parent_is_valid_or_create_message(Chouette::Company, route.agency_id, resource)
      end
      line = line_referential.lines.find_or_initialize_by(registration_number: route.id)
      line.name = route.long_name.presence || route.short_name
      line.number = route.short_name
      line.published_name = route.long_name
      line.company = line_referential.companies.find_by(registration_number: route.agency_id) if route.agency_id.present?
      line.comment = route.desc

      line.transport_mode = case route.type
                            when '0', '5'
                              'tram'
                            when '1'
                              'metro'
                            when '2'
                              'rail'
                            when '3'
                              'bus'
                            when '7'
                              'funicular'
                            end

      # TODO: colors

      line.url = route.url

      save_model line, resource: resource
    end
  end

  def vehicle_journey_by_trip_id
    @vehicle_journey_by_trip_id ||= {}
  end

  def import_trips
    @trips = {}
    create_resource(:trips).each(source.trips, slice: 100, transaction: true) do |trip, resource|
      @trips[trip.id] = trip
    end
  end

  def import_stop_times
    # routes = Set.new
    prev_trip_id = nil
    to_be_saved = []
    create_resource(:stop_times).each(
      source.stop_times.group_by(&:trip_id),
      slice: 10,
      transaction: true,
      memory_profile: -> { "Import stop times from #{rows_count}" }
    ) do |row, resource|
      begin
        trip_id, stop_times = row
        to_be_saved = []
        prev_trip_id = trip_id

        trip = @trips[trip_id]
        line = line_referential.lines.find_by registration_number: trip.route_id
        route = referential.routes.build line: line
        route.wayback = (trip.direction_id == '0' ? :outbound : :inbound)
        name = route.published_name = trip.headsign.presence || trip.short_name.presence || route.wayback.to_s.capitalize
        route.name = name
        to_be_saved << route

        journey_pattern = route.journey_patterns.build name: name
        # to_be_saved << journey_pattern

        vehicle_journey = journey_pattern.vehicle_journeys.build route: route
        vehicle_journey.published_journey_name = trip.short_name.presence || trip.id

        to_be_saved << vehicle_journey

        time_table = referential.time_tables.find_by(id: time_tables_by_service_id[trip.service_id]) if time_tables_by_service_id[trip.service_id]
        if time_table
          vehicle_journey.time_tables << time_table
        else
          create_message(
            {
              criticity: :warning,
              message_key: 'gtfs.trips.unknown_service_id',
              message_attributes: { service_id: trip.service_id },
              resource_attributes: {
                filename: "#{resource.name}.txt",
                line_number: resource.rows_count,
                column_number: 0
              }
            },
            resource: resource,
            commit: true
          )
        end

        stop_times.sort_by! { |s| s.stop_sequence.to_i }

        raise InvalidTripTimesError unless consistent_stop_times(stop_times)

        stop_points = stop_times.map do |stop_time|
          [stop_time, import_stop_time(stop_time, route, resource)]
        end
        to_be_saved.each do |model|
          save_model model, resource: resource
        end
        stop_points.each do |stop_time, stop_point|
          next if stop_point.nil?
          add_stop_point stop_time, stop_point, journey_pattern, resource
        end
        save_model journey_pattern, resource: resource

      rescue Import::Gtfs::InvalidTripNonZeroFirstOffsetError, Import::Gtfs::InvalidTripTimesError => e
        message_key = e.is_a?(Import::Gtfs::InvalidTripNonZeroFirstOffsetError) ? 'trip_starting_with_non_zero_day_offset' : 'trip_with_inconsistent_stop_times'
        create_message(
          {
            criticity: :error,
            message_key: message_key,
            message_attributes: {
              trip_id: vehicle_journey.published_journey_name
            },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource, commit: true
        )
        @status = 'failed'
      rescue Import::Gtfs::InvalidTimeError => e
        create_message(
          {
            criticity: :error,
            message_key: 'invalid_stop_time',
            message_attributes: {
              time: e.time,
              trip_id: vehicle_journey.published_journey_name
            },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource, commit: true
        )
        @status = 'failed'
      end
    end
  end

  def consistent_stop_times(stop_times)
    times = stop_times.map{|s| [s.arrival_time, s.departure_time]}.flatten.compact
    times.inject(nil) do |prev, current|
      current = current.split(':').map &:to_i

      if prev
        return false if prev.first > current.first
        return false if prev.first == current.first && prev[1] > current[1]
        return false if prev.first == current.first && prev[1] == current[1] && prev[2] > current[2]
      end

      current
    end
    true
  end

  def import_stop_time(stop_time, route, resource)
    unless_parent_model_in_error(Chouette::StopArea, stop_time.stop_id, resource) do

      if stop_time.stop_sequence.to_i == 1 # first stop has stop_sequence == 1
        departure_time = GTFS::Time.parse(stop_time.departure_time)
        raise InvalidTimeError.new(stop_time.departure_time) unless departure_time.present?
        arrival_time = GTFS::Time.parse(stop_time.arrival_time)
        raise InvalidTimeError.new(stop_time.arrival_time) unless arrival_time.present?
        raise InvalidTripNonZeroFirstOffsetError unless departure_time.day_offset.zero? && arrival_time.day_offset.zero?
      end

      stop_area = stop_area_referential.stop_areas.find_by(registration_number: stop_time.stop_id)
      stop_point = route.stop_points.build stop_area: stop_area

      stop_point
    end
  end

  def add_stop_point(stop_time, stop_point, journey_pattern, resource)
    journey_pattern.stop_points << stop_point
    # JourneyPattern#vjas_add creates automaticaly VehicleJourneyAtStop
    vehicle_journey_at_stop = journey_pattern.vehicle_journey_at_stops.where(stop_point_id: stop_point.id).last
    departure_time = GTFS::Time.parse(stop_time.departure_time)
    raise InvalidTimeError.new(stop_time.departure_time) unless departure_time.present?

    arrival_time = GTFS::Time.parse(stop_time.arrival_time)
    raise InvalidTimeError.new(stop_time.arrival_time) unless arrival_time.present?

    if @previous_stop_sequence.nil? || stop_time.stop_sequence.to_i <= @previous_stop_sequence
      @vehicle_journey_at_stop_first_offset = departure_time.day_offset
    end

    vehicle_journey_at_stop.departure_time = departure_time.time
    vehicle_journey_at_stop.arrival_time = arrival_time.time
    vehicle_journey_at_stop.departure_day_offset = departure_time.day_offset - @vehicle_journey_at_stop_first_offset
    vehicle_journey_at_stop.arrival_day_offset = arrival_time.day_offset - @vehicle_journey_at_stop_first_offset

    # TODO: offset

    @previous_stop_sequence = stop_time.stop_sequence.to_i

    save_model vehicle_journey_at_stop, resource: resource
  end

  def time_tables_by_service_id
    @time_tables_by_service_id ||= {}
  end

  def import_calendars
    create_resource(:calendars).each(source.calendars, slice: 500, transaction: true) do |calendar, resource|
      time_table = referential.time_tables.build comment: "Calendar #{calendar.service_id}"
      Chouette::TimeTable.all_days.each do |day|
        time_table.send("#{day}=", calendar.send(day))
      end
      time_table.periods.build period_start: calendar.start_date, period_end: calendar.end_date
      save_model time_table, resource: resource

      time_tables_by_service_id[calendar.service_id] = time_table.id
    end
  end

  def import_calendar_dates
    return unless source.entries.include?('calendar_dates.txt')

    create_resource(:calendar_dates).each(source.calendar_dates, slice: 500, transaction: true) do |calendar_date, resource|
      comment = "Calendar #{calendar_date.service_id}"
      unless_parent_model_in_error(Chouette::TimeTable, comment, resource) do
        time_table = referential.time_tables.where(id: time_tables_by_service_id[calendar_date.service_id]).last
        time_table ||= begin
          tt = referential.time_tables.build comment: comment
          save_model tt, resource: resource
          time_tables_by_service_id[calendar_date.service_id] = tt.id
          tt
        end

        date = time_table.dates.build date: Date.parse(calendar_date.date), in_out: calendar_date.exception_type == "1"
        save_model date, resource: resource
      end
    end
  end

  def save_model(model, filename: nil, line_number:  nil, column_number: nil, resource: nil)
    if resource
      filename ||= "#{resource.name}.txt"
      line_number ||= resource.rows_count
      column_number ||= 0
    end

    unless model.save
      Rails.logger.error "Can't save #{model.class.name} : #{model.errors.inspect}"

      model.errors.details.each do |key, messages|
        messages.each do |message|
          message.each do |criticity, error|
            if Import::Message.criticity.values.include?(criticity.to_s)
              create_message(
                {
                  criticity: criticity,
                  message_key: error,
                  message_attributes: {
                    test_id: key,
                    object_attribute: key,
                    source_attribute: key,
                  },
                  resource_attributes: {
                    filename: filename,
                    line_number: line_number,
                    column_number: column_number
                  }
                },
                resource: resource,
                commit: true
              )
            end
          end
        end
      end
      @models_in_error ||= Hash.new { |hash, key| hash[key] = [] }
      @models_in_error[model.class.name] << model_key(model)
      @status = "failed"
      return
    end

    Rails.logger.debug "Created #{model.inspect}"
  end

  def check_parent_is_valid_or_create_message(klass, key, resource)
    if @models_in_error&.key?(klass.name) && @models_in_error[klass.name].include?(key)
      create_message(
        {
          criticity: :error,
          message_key: :invalid_parent,
          message_attributes: {
            parent_class: klass,
            parent_key: key,
            test_id: :parent,
          },
          resource_attributes: {
            filename: "#{resource.name}.txt",
            line_number: resource.rows_count,
            column_number: 0
          }
        },
        resource: resource, commit: true
      )
      return false
    end
    true
  end

  def find_stop_parent_or_create_message(stop_area_name, parent_station, resource)
    parent = stop_area_referential.stop_areas.find_by(registration_number: parent_station)
    unless parent
      create_message(
        {
          criticity: :error,
          message_key: :parent_not_found,
          message_attributes: {
            parent_name: parent_station,
            stop_area_name: stop_area_name,
          },
          resource_attributes: {
            filename: "#{resource.name}.txt",
            line_number: resource.rows_count,
            column_number: 0
          }
        },
        resource: resource, commit: true
      )
    end
    return parent
  end

  def unless_parent_model_in_error(klass, key, resource)
    return unless check_parent_is_valid_or_create_message(klass, key, resource)

    yield
  end

  def model_key(model)
    return model.registration_number if model.respond_to?(:registration_number)

    return model.comment if model.is_a?(Chouette::TimeTable)
    return model.checksum_source if model.is_a?(Chouette::VehicleJourneyAtStop)

    model.objectid
  end

  def notify_parent
    return unless super

    main_resource.update_status_from_importer self.status
    next_step
  end

  class InvalidTripNonZeroFirstOffsetError < StandardError; end
  class InvalidTripTimesError < StandardError; end
  class InvalidTimeError < StandardError
    attr_reader :time

    def initialize(time)
      @time = time
    end
  end
end
