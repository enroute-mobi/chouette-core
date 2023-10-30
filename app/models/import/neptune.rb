class Import::Neptune < Import::Base
  include LocalImportSupport

  def self.accepts_file?(file)
    ::Neptune::Source.accept?(file)
  rescue => e
    Chouette::Safe.capture "Error in testing Neptune file: #{file}", e
    return false
  end

  def steps_count
    # does not account for create_referential and save_current
    6
  end

  def import_without_status
    prepare_referential

    import_resources :time_tables
    fix_metadatas_periodes
    import_resources :stop_areas, :lines_content
  end

  def prepare_referential
    import_resources :companies, :networks, :lines

    create_referential
    referential.switch
  end

  def referential_metadata
    # we use a mock periode, and will fix it once we have imported the timetables
    periode = (Time.now..1.month.from_now)
    ReferentialMetadata.new line_ids: @imported_line_ids, periodes: [periode]
  end

  protected

  def each_source
    Zip::File.open(local_file) do |zip_file|
      @source_count ||= zip_file.glob('*.xml').count
      zip_file.glob('*.xml').each do |f|
        yield Nokogiri::XML(f.get_input_stream), f.name
      end
    end
  end

  def each_element_matching_css(selector, root=nil)
    if root
      coll = root[:_node].css(selector)
      coll.map(&method(:build_object_from_nokogiri_element))\
          .each_with_index do |object, i|
          yield object, nil, i * 1.0 / coll.count
      end
    else
      counter = 0
      each_source do |source, filename|
        coll = source.css(selector)
        coll.map(&method(:build_object_from_nokogiri_element))\
            .each do |object|
            yield object, filename, counter * 1.0 / coll.count / @source_count
            counter += 1
        end
      end
    end
  end

  def get_associated_network(source_pt_network, filename)
    network = nil
    each_element_matching_css('PTNetwork', source_pt_network) do |source_network, filename, progress|
      if network
        create_message(
          criticity: :warning,
          message_key: "multiple_networks_in_file",
          message_attributes: { source_filename: filename }
        )
        return
      end
      network = networks.find_by registration_number: source_network[:object_id]
    end
    network
  end

  def get_associated_company(source_pt_network, filename)
    company = nil
    each_element_matching_css('Company', source_pt_network) do |source_company, filename, progress|
      if company
        create_message(
          criticity: :warning,
          message_key: "multiple_companies_in_file",
          message_attributes: { source_filename: filename }
        )
        return
      end
      company = companies.find_by registration_number: source_company[:object_id]
    end
    company
  end

  def import_lines
    each_element_matching_css('ChouettePTNetwork') do |source_pt_network, filename, progress|
      file_company = get_associated_company(source_pt_network, filename)
      file_network = get_associated_network(source_pt_network, filename)

      each_element_matching_css('ChouetteLineDescription Line', source_pt_network) do |source_line, _|
        line = lines.find_or_initialize_by registration_number: source_line[:object_id]
        line.line_provider = line_provider
        line.name = source_line[:name] if source_line[:name]
        line.number = source_line[:number] if source_line[:number]
        # Ignore dummy published_name (filled with line number)
        unless source_line[:published_name].nil? || source_line[:published_name] == line.number
          line.published_name = source_line[:published_name]
        end
        line.comment = source_line[:comment] if source_line[:comment]

        transport_mode, transport_submode = transport_mode_name_mapping(source_line[:transport_mode_name])
        if transport_mode && transport_submode
          line.transport_mode, line.transport_submode = transport_mode, transport_submode
        end
        line.company = file_company if file_company
        line.network = file_network if file_network

        save_model line
        @imported_line_ids ||= []
        @imported_line_ids << line.id
      end
    end
  end

  def import_companies
    each_element_matching_css('ChouettePTNetwork Company') do |source_company, _, progress|
      company = companies.find_or_initialize_by registration_number: source_company.delete(:object_id)
      company.line_provider = line_provider
      company.assign_attributes source_company.slice(:name, :short_name, :code, :default_contact_phone, :default_contact_email, :default_contact_fax, :default_contact_organizational_unit, :default_contact_operating_department_name)
      company.time_zone = DEFAULT_TIME_ZONE
      save_model company
    end
  end

  def import_networks
    each_element_matching_css('ChouettePTNetwork PTNetwork') do |source_network, filename, progress|
      network = networks.find_or_initialize_by registration_number: source_network.delete(:object_id)
      network.line_provider = line_provider
      network.assign_attributes source_network.slice(:name, :comment)

      save_model network
    end
  end

  def import_time_tables
    @time_tables = Hash.new{|h, k| h[k] = []}
    @imported_time_tables = []
    each_element_matching_css('ChouettePTNetwork Timetable') do |source_timetable, filename, progress|
      tt = Chouette::TimeTable.find_or_initialize_by objectid: source_timetable[:object_id]
      unless @imported_time_tables.include?(tt.object_id)
        @imported_time_tables << tt.object_id
        tt.int_day_types = int_day_types_mapping source_timetable[:day_type]
        tt.created_at = source_timetable[:creation_time].presence
        tt.comment = source_timetable[:comment].presence || source_timetable[:object_id]
        tt.metadata = { creator_username: source_timetable[:creator_id] }
        save_model tt
        add_time_table_dates tt, source_timetable[:calendar_day]
        add_time_table_periods tt, source_timetable[:period]
      end

      make_enum(source_timetable[:vehicle_journey_id]).each do |vehicle_journey_id|
        @time_tables[vehicle_journey_id] << tt.id
      end
    end
  end

  def add_time_table_dates(timetable, dates)
    return unless dates

    make_enum(dates).each do |date|
      @timetables_period_start = [@timetables_period_start, date.to_date].compact.min
      @timetables_period_end = [@timetables_period_end, date.to_date].compact.max
      next if timetable.dates.where(in_out: true, date: date).exists?

      timetable.dates.create(in_out: true, date: date)
    end
  end

  def add_time_table_periods(timetable, periods)
    return unless periods

    make_enum(periods).each do |period|
      @timetables_period_start = [@timetables_period_start, period[:start_of_period].to_date].compact.min
      @timetables_period_end = [@timetables_period_end, period[:end_of_period].to_date].compact.max

      next if timetable.periods.where(period_start: period[:start_of_period], period_end: period[:end_of_period]).exists?
      timetable.periods.create(period_start: period[:start_of_period], period_end: period[:end_of_period])
    end

    timetable.periods = timetable.optimize_overlapping_periods.map {|p| p.time_table_id = timetable.id; p.save; p }
  end

  def int_day_types_mapping day_types
    day_types = make_enum day_types

    val = 0
    day_types.each do |day_type|
      day_value = case day_type.downcase
      when 'monday'
        Chouette::TimeTable::MONDAY
      when 'tuesday'
        Chouette::TimeTable::TUESDAY
      when 'wednesday'
        Chouette::TimeTable::WEDNESDAY
      when 'thursday'
        Chouette::TimeTable::THURSDAY
      when 'friday'
        Chouette::TimeTable::FRIDAY
      when 'saturday'
        Chouette::TimeTable::SATURDAY
      when 'sunday'
        Chouette::TimeTable::SUNDAY
      when 'weekday'
        Chouette::TimeTable::MONDAY | Chouette::TimeTable::TUESDAY | Chouette::TimeTable::WEDNESDAY | Chouette::TimeTable::THURSDAY  | Chouette::TimeTable::FRIDAY
      when 'weekend'
        Chouette::TimeTable::SATURDAY | Chouette::TimeTable::SUNDAY
      end
      val = val | day_value if day_value
    end
    val
  end

  def fix_metadatas_periodes
    referential.metadatas.last.update periodes: [(@timetables_period_start..@timetables_period_end)]
  end

  def transport_mode_name_mapping(source_transport_mode)
    {
      'Air' => nil,
      'Train' => ['rail', 'regionalRail'],
      'LongDistanceTrain' => ['rail', 'interregionalRail'],
      'LocalTrain' => ['rail', 'suburbanRailway'],
      'RapidTransit' => ['rail', 'railShuttle'],
      'Metro' => ['metro', 'undefined'],
      'Tramway' => ['tram', 'undefined'],
      'Coach' => ['bus', 'undefined'],
      'Bus' => ['bus', 'undefined'],
      'Ferry' => nil,
      'Waterborne' => nil,
      'PrivateVehicle' => nil,
      'Walk' => nil,
      'Trolleybus' => ['tram', 'undefined'],
      'Bicycle' => nil,
      'Shuttle' => ['bus', 'airportLinkBus'],
      'Taxi' => nil,
      'VAL' => ['rail', 'railShuttle'],
      'Other' => nil
    }[source_transport_mode]
  end

  def import_stop_areas
    @parent_stop_areas = {}
    stop_area_registration_numbers = Set.new

    each_element_matching_css('ChouettePTNetwork ChouetteArea') do |source_parent, _, progress|
      coordinates = {}
      each_element_matching_css('AreaCentroid', source_parent) do |centroid|
        coordinates[centroid[:object_id]] = centroid.slice(:latitude, :longitude)
      end

      each_element_matching_css('StopArea', source_parent) do |source_stop_area|
        stop_area = stop_areas.find_or_initialize_by registration_number: source_stop_area[:object_id]
        stop_area.name = source_stop_area[:name] if source_stop_area[:name].present?
        stop_area.comment = source_stop_area[:comment] if source_stop_area[:comment].present?

        stop_area.time_zone = DEFAULT_TIME_ZONE

        if (street_name = source_stop_area[:address].try(:[], :street_name)).present?
          stop_area.street_name = street_name
        end
        if (extension = source_stop_area[:stop_area_extension])
          stop_area.nearest_topic_name = extension[:nearest_topic_name] if extension[:nearest_topic_name].present?
          stop_area.fare_code = extension[:fare_code] if extension[:fare_code].present?
          stop_area.area_type = stop_area_type_mapping(extension[:area_type]) if extension[:area_type].present?
        end
        stop_area.kind = :commercial
        if source_stop_area[:centroid_of_area]
          latitude = coordinates[source_stop_area[:centroid_of_area]].try(:[], :latitude)
          longitude = coordinates[source_stop_area[:centroid_of_area]].try(:[], :longitude)

          if latitude && longitude
            stop_area.latitude, stop_area.longitude = latitude, longitude
          end
        end

        stop_area.activate
        save_model stop_area

        if stop_area.persisted?
          contains = make_enum(source_stop_area[:contains])
          contains.each do |child_registration_number|
            @parent_stop_areas[child_registration_number] = stop_area.id
          end

          stop_area_registration_numbers << source_stop_area[:object_id]
        end
      end
    end

    # Update all StopAreas with their parent
    stop_area_registration_numbers.each do |child_registration_number|
      child = stop_areas.find_by registration_number: child_registration_number
      next unless child

      parent_id = @parent_stop_areas.delete(child_registration_number)
      child.update parent_id: parent_id
    end
  end

  def stop_area_type_mapping(source_stop_area_type)
    {
      'BoardingPosition' => :zdep,
      'Quay' =>  :zdep,
      'CommercialStopPoint' => 	:zdlp,
      'StopPlace' => :lda
    }[source_stop_area_type]
  end

  def import_lines_content
    @opposite_route_id = {}
    each_element_matching_css('ChouettePTNetwork ChouetteLineDescription') do |line_desc, filename, progress|
      line = lines.find_by registration_number: line_desc[:line][:object_id]
      @routes = {}
      @stop_points = Hash.new{|h, k| h[k] = {}}

      import_routes_in_line(line, line_desc[:chouette_route], line_desc)

      @journey_patterns = {}
      import_journey_patterns_in_line(line, line_desc[:journey_pattern])
      import_vehicle_journeys_in_line(line, line_desc[:vehicle_journey])
    end
  end

  def import_routes_in_line(line, source_routes, line_desc)
    profile_tag :import_routes_in_line do
      source_routes = make_enum source_routes

      source_routes.each do |source_route|
        published_name = source_route[:published_name] || source_route[:name]
        route = line.routes.build do |r|
          r.published_name = published_name
          r.name = source_route[:name]
          r.wayback = route_wayback_mapping source_route[:route_extension][:way_back]
          r.metadata = { creator_username: source_route[:creator_id], created_at: source_route[:creation_time] }
          r.opposite_route_id = @opposite_route_id.delete source_route[:object_id]
        end

        add_stop_points_to_route(route, source_route[:pt_link_id], line_desc[:pt_link], source_route[:object_id])
        save_model route

        if source_route[:way_back_route_id].present? && !route.opposite_route_id
          @opposite_route_id[source_route[:way_back_route_id]] = route.id
        end
        @routes[source_route[:object_id]] = route
      end
    end
  end

  def import_journey_patterns_in_line(line, source_journey_patterns)
    profile_tag :import_journey_patterns_in_line do
      source_journey_patterns = make_enum source_journey_patterns

      source_journey_patterns.each do |source_journey_pattern|
        route = @routes[source_journey_pattern[:route_id]]
        journey_pattern = route.journey_patterns.build do |j|
          j.published_name = source_journey_pattern[:published_name]
          j.registration_number = source_journey_pattern[:registration].try(:[], :registration_number)
          j.name = source_journey_pattern[:name]
          j.metadata = { creator_username: source_journey_pattern[:creator_id], created_at: source_journey_pattern[:creation_time] }
        end

        add_stop_points_to_journey_pattern(journey_pattern, source_journey_pattern[:stop_point_list], source_journey_pattern[:route_id])
        save_model journey_pattern
        @journey_patterns[source_journey_pattern[:object_id]] = journey_pattern
      end
    end
  end

  def import_vehicle_journeys_in_line(line, source_vehicle_journeys)
    profile_tag :import_vehicle_journeys_in_line do
      source_vehicle_journeys = make_enum source_vehicle_journeys

      source_vehicle_journeys.each do |source_vehicle_journey|
        if source_vehicle_journey[:journey_pattern_id]
          journey_pattern = @journey_patterns[source_vehicle_journey[:journey_pattern_id]]
        else
          journey_pattern = @routes[source_vehicle_journey[:route_id]].journey_patterns.last
        end
        vehicle_journey = journey_pattern.vehicle_journeys.build do |v|
          v.published_journey_identifier = source_vehicle_journey[:number]
          if source_vehicle_journey[:number] =~ /\A[0-9]+\z/
            v.number = source_vehicle_journey[:number].to_i
          end
          v.published_journey_name = source_vehicle_journey[:published_journey_name]
          v.route = journey_pattern.route
          v.metadata = { creator_username: source_vehicle_journey[:creator_id], created_at: source_vehicle_journey[:creation_time] }
          v.transport_mode, _ = transport_mode_name_mapping(source_vehicle_journey[:transport_mode_name])
          v.company = companies.find_by registration_number: source_vehicle_journey[:operator_id]
          v.time_table_ids = @time_tables.delete(source_vehicle_journey[:object_id])

          v.codes.build code_space: code_space, value: source_vehicle_journey[:object_id]
        end
        add_stop_points_to_vehicle_journey(vehicle_journey, source_vehicle_journey[:vehicle_journey_at_stop], source_vehicle_journey[:route_id])

        save_model vehicle_journey
      end
    end
  end

  def add_stop_points_to_route(route, link_ids, links, route_object_id)
    link_ids = make_enum link_ids
    links = make_enum links

    route.stop_points.destroy_all

    last_point_id = nil
    link_ids.each_with_index do |link_id, i|
      link = links.find{|l| l[:object_id] == link_id }
      stop_point_id = link[:start_of_link]
      last_point_id = link[:end_of_link]
      add_stop_point_to_route(stop_point_id, route, i, route_object_id)
    end
    add_stop_point_to_route(last_point_id, route, route.stop_points.size, route_object_id)
  end

  def add_stop_point_to_route(stop_point_id, route, pos, route_object_id)
    stop_area_id = @parent_stop_areas[stop_point_id]
    stop_point = route.stop_points.build stop_area_id: stop_area_id, position: pos
    @stop_points[route_object_id][stop_point_id] = stop_point
  end

  def add_stop_points_to_journey_pattern(journey_pattern, stop_point_ids, route_object_id)
    stop_point_ids = make_enum stop_point_ids

    journey_pattern.stop_points.destroy_all

    stop_point_ids.each do |stop_point_id|
      journey_pattern.stop_points << @stop_points[route_object_id][stop_point_id]
    end
  end

  DEFAULT_UTC_OFFSET = 3600
  DEFAULT_TIME_ZONE = "Europe/Paris"

  def add_stop_points_to_vehicle_journey(vehicle_journey, vehicle_journey_at_stops, route_object_id)
    vehicle_journey_at_stops = make_enum vehicle_journey_at_stops

    vehicle_journey.vehicle_journey_at_stops.destroy_all

    vehicle_journey_at_stops.sort_by{|i| i[:order]&.to_i}.each_with_index do |source_vehicle_journey_at_stop, index|
      vehicle_journey.vehicle_journey_at_stops.build do |vehicle_journey_at_stop|
        vehicle_journey_at_stop.stop_point = @stop_points[route_object_id][source_vehicle_journey_at_stop[:stop_point_id]]

        departure_time_of_day = TimeOfDay.parse(source_vehicle_journey_at_stop[:departure_time], utc_offset: DEFAULT_UTC_OFFSET)
        vehicle_journey_at_stop.departure_time_of_day = departure_time_of_day

        arrival_time_of_day =
          if index > 0
            TimeOfDay.parse(source_vehicle_journey_at_stop[:arrival_time], utc_offset: DEFAULT_UTC_OFFSET)
          else
            departure_time_of_day
          end

        vehicle_journey_at_stop.arrival_time_of_day = arrival_time_of_day
      end
    end
  end

  def route_wayback_mapping(source_value)
    {'a' => :outbound, 'aller' => :outbound, 'r' => 'inbound', 'retour' => 'inbound'}[source_value.downcase]
  end

  def build_object_from_nokogiri_element(element)
    out = { _node: element }
    element.elements.each do |child|
      key = child.name.underscore.to_sym

      if child.elements.present?
        content = build_object_from_nokogiri_element(child)
      else
        content = child.content
        next if content == ""
      end

      # To manage several elements with the same name
      if element.elements.select{ |c| c.name == child.name }.count > 1
        out[key] ||= []
        out[key] << content
      else
        out[key] = content
      end
    end
    out
  end

  def make_enum(obj)
    (obj.is_a?(Array) ? obj : [obj]).compact
  end

  def stop_areas
    stop_area_provider.stop_areas
  end

  def lines
    line_referential.lines.by_provider(line_provider)
  end

  def companies
    line_referential.companies.by_provider(line_provider)
  end

  def networks
    line_referential.networks.by_provider(line_provider)
  end
end
