class Import::Neptune < Import::Base
  include LocalImportSupport

  def self.accepts_file?(file)
    Zip::File.open(file) do |zip_file|
      files_count = zip_file.glob('*').size
      files_count -= zip_file.glob('metadata*.txt').size
      zip_file.glob('*.xml').size == files_count
    end
  rescue => e
    Rails.logger.debug "Error in testing Neptune file: #{e}"
    return false
  end

  def launch_worker
    delay.import
  end

  def import_without_status
    prepare_referential
    referential.pending!

    import_resources :time_tables
    fix_metadatas_periodes
    import_resources :stop_areas, :lines_content
  end

  def prepare_referential
    import_resources :lines, :companies, :networks

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
      zip_file.glob('*.xml').each do |f|
        yield Nokogiri::XML(f.get_input_stream), f.name
      end
    end
  end

  def each_element_matching_css(selector, root=nil)
    if root
      root[:_node].css(selector)\
            .map(&method(:build_object_from_nokogiri_element))\
            .each do |object|
          yield object
      end
    else
      each_source do |source, filename|
        source.css(selector)\
              .map(&method(:build_object_from_nokogiri_element))\
              .each do |object|
            yield object, filename
        end
      end
    end
  end

  def get_associated_network(source_pt_network, filename)
    network = nil
    each_element_matching_css('PTNetwork', source_pt_network) do |source_network|
      if network
        create_message(
          criticity: :warning,
          message_key: "multiple_networks_in_file",
          message_attributes: { source_filename: filename }
        )
        return
      end
      network = line_referential.networks.find_by registration_number: source_network[:object_id]
    end
    network
  end

  def get_associated_company(source_pt_network, filename)
    company = nil
    each_element_matching_css('Company', source_pt_network) do |source_company, filename|
      if company
        create_message(
          criticity: :warning,
          message_key: "multiple_companies_in_file",
          message_attributes: { source_filename: filename }
        )
        return
      end
      company = line_referential.companies.find_by registration_number: source_company[:object_id]
    end
    company
  end

  def import_lines
    each_element_matching_css('ChouettePTNetwork') do |source_pt_network, filename|
      file_company = get_associated_company(source_pt_network, filename)
      file_network = get_associated_network(source_pt_network, filename)

      each_element_matching_css('ChouetteLineDescription Line', source_pt_network) do |source_line|
        line = line_referential.lines.find_or_initialize_by registration_number: source_line[:object_id]
        line.name = source_line[:name]
        line.number = source_line[:number]
        line.published_name = source_line[:published_name]
        line.comment = source_line[:comment]
        line.transport_mode, line.transport_submode = transport_mode_name_mapping(source_line[:transport_mode_name])
        line.company = file_company
        line.network = file_network

        save_model line
        @imported_line_ids ||= []
        @imported_line_ids << line.id
      end
    end
  end

  def import_companies
    each_element_matching_css('ChouettePTNetwork Company') do |source_company|
      company = line_referential.companies.find_or_initialize_by registration_number: source_company.delete(:object_id)
      company.assign_attributes source_company.slice(:name, :short_name, :code, :phone, :email, :fax, :organizational_unit, :operating_department_name)

      save_model company
    end
  end

  def import_networks
    each_element_matching_css('ChouettePTNetwork PTNetwork') do |source_network|
      network = line_referential.networks.find_or_initialize_by registration_number: source_network.delete(:object_id)
      network.assign_attributes source_network.slice(:name, :comment)

      save_model network
    end
  end

  def import_time_tables
    @time_tables = Hash.new{|h, k| h[k] = []}
    each_element_matching_css('ChouettePTNetwork Timetable') do |source_timetable|
      tt = Chouette::TimeTable.find_or_initialize_by objectid: source_timetable[:object_id]
      tt.int_day_types = int_day_types_mapping source_timetable[:day_type]
      tt.created_at = source_timetable[:creation_time]
      tt.comment = source_timetable[:comment].presence || source_timetable[:object_id]
      tt.metadata = { creator_username: source_timetable[:creator_id] }
      save_model tt
      add_time_table_dates tt, source_timetable[:calendar_day]
      add_time_table_periods tt, source_timetable[:period]
      make_enum(source_timetable[:vehicle_journey_id]).each do |vehicle_journey_id|
        @time_tables[vehicle_journey_id] << tt.id
      end
    end
  end

  def add_time_table_dates(timetable, dates)
    return unless dates

    dates = make_enum dates
    dates.each do |date|
      @timetables_period_start = [@timetables_period_start, date.to_date].compact.min
      @timetables_period_end = [@timetables_period_end, date.to_date].compact.max
      next if timetable.dates.where(in_out: true, date: date).exists?

      timetable.dates.create(in_out: true, date: date)
    end
  end

  def add_time_table_periods(timetable, periods)
    return unless periods

    periods = make_enum periods
    periods.each do |period|
      @timetables_period_start = [@timetables_period_start, period[:start_of_period].to_date].compact.min
      @timetables_period_end = [@timetables_period_end, period[:end_of_period].to_date].compact.max

      timetable.periods.build(period_start: period[:start_of_period], period_end: period[:end_of_period])
    end
    timetable.periods = timetable.optimize_overlapping_periods
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
      'Metro' => ['metro', nil],
      'Tramway' => ['tram', nil],
      'Coach' => ['bus', nil],
      'Bus' => ['bus', nil],
      'Ferry' => nil,
      'Waterborne' => nil,
      'PrivateVehicle' => nil,
      'Walk' => nil,
      'Trolleybus' => ['tram', nil],
      'Bicycle' => nil,
      'Shuttle' => ['bus', 'airportLinkBus'],
      'Taxi' => nil,
      'VAL' => ['rail', 'railShuttle'],
      'Other' => nil
    }[source_transport_mode]
  end

  def import_stop_areas
    @parent_stop_areas = {}
    each_element_matching_css('ChouettePTNetwork ChouetteArea') do |source_parent|
      coordinates = {}
      each_element_matching_css('AreaCentroid', source_parent) do |centroid|
        coordinates[centroid[:object_id]] = centroid.slice(:latitude, :longitude)
      end

      each_element_matching_css('StopArea', source_parent) do |source_stop_area|
        stop_area = stop_area_referential.stop_areas.find_or_initialize_by registration_number: source_stop_area[:object_id]
        stop_area.name = source_stop_area[:name]
        stop_area.comment = source_stop_area[:comment]
        stop_area.street_name = source_stop_area[:address].try(:[], :street_name)
        stop_area.nearest_topic_name = source_stop_area[:nearest_topic_name]
        stop_area.fare_code = source_stop_area[:fare_code]
        stop_area.area_type = stop_area_type_mapping(source_stop_area[:stop_area_extension][:area_type])
        stop_area.kind = :commercial
        if source_stop_area[:centroid_of_area]
          stop_area.latitude = coordinates[source_stop_area[:centroid_of_area]].try(:[], :latitude)
          stop_area.longitude = coordinates[source_stop_area[:centroid_of_area]].try(:[], :longitude)
        end
        stop_area.parent_id = @parent_stop_areas.delete(source_stop_area[:object_id])

        save_model stop_area

        contains = source_stop_area[:contains]
        contains = make_enum contains
        contains.each do |child_registration_number|
          @parent_stop_areas[child_registration_number] = stop_area.id
        end
      end
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
    each_element_matching_css('ChouettePTNetwork ChouetteLineDescription') do |line_desc|
      line = line_referential.lines.find_by registration_number: line_desc[:line][:object_id]
      @routes = {}
      @stop_points = Hash.new{|h, k| h[k] = {}}

      import_routes_in_line(line, line_desc[:chouette_route], line_desc)

      @journey_patterns = {}
      import_journey_patterns_in_line(line, line_desc[:journey_pattern])
      import_vehicle_journeys_in_line(line, line_desc[:vehicle_journey])
    end
  end

  def import_routes_in_line(line, source_routes, line_desc)
    source_routes = make_enum source_routes

    source_routes.each do |source_route|
      published_name = source_route[:published_name] || source_route[:name]
      route = line.routes.build do |route|
        route.published_name = published_name
        route.name = source_route[:name]
        route.wayback = route_wayback_mapping source_route[:route_extension][:way_back]
        route.metadata = { creator_username: source_route[:creator_id], created_at: source_route[:creation_time] }
        route.opposite_route_id = @opposite_route_id.delete source_route[:object_id]
      end

      add_stop_points_to_route(route, source_route[:pt_link_id], line_desc[:pt_link], source_route[:object_id])
      save_model route

      if source_route[:way_back_route_id].present? && !route.opposite_route_id
        @opposite_route_id[source_route[:way_back_route_id]] = route.id
      end
      @routes[source_route[:object_id]] = route
    end
  end

  def import_journey_patterns_in_line(line, source_journey_patterns)
    source_journey_patterns = make_enum source_journey_patterns

    source_journey_patterns.each do |source_journey_pattern|
      route = @routes[source_journey_pattern[:route_id]]
      journey_pattern = route.journey_patterns.build do |journey_pattern|
        journey_pattern.published_name = source_journey_pattern[:published_name]
        journey_pattern.registration_number = source_journey_pattern[:registration].try(:[], :registration_number)
        journey_pattern.name = source_journey_pattern[:name]
        journey_pattern.metadata = { creator_username: source_journey_pattern[:creator_id], created_at: source_journey_pattern[:creation_time] }
      end

      add_stop_points_to_journey_pattern(journey_pattern, source_journey_pattern[:stop_point_list], source_journey_pattern[:route_id])
      save_model journey_pattern
      @journey_patterns[source_journey_pattern[:object_id]] = journey_pattern
    end
  end

  def import_vehicle_journeys_in_line(line, source_vehicle_journeys)
    source_vehicle_journeys = make_enum source_vehicle_journeys

    source_vehicle_journeys.each do |source_vehicle_journey|
      if source_vehicle_journey[:journey_pattern_id]
        journey_pattern = @journey_patterns[source_vehicle_journey[:journey_pattern_id]]
      else
        journey_pattern = @routes[source_vehicle_journey[:route_id]].journey_patterns.last
      end
      vehicle_journey = journey_pattern.vehicle_journeys.build do |vehicle_journey|
        vehicle_journey.number =  source_vehicle_journey[:number]
        vehicle_journey.published_journey_name = source_vehicle_journey[:published_journey_name]
        vehicle_journey.route = journey_pattern.route
        vehicle_journey.metadata = { creator_username: source_vehicle_journey[:creator_id], created_at: source_vehicle_journey[:creation_time] }
        vehicle_journey.transport_mode, _ = transport_mode_name_mapping(source_vehicle_journey[:transport_mode_name])
        vehicle_journey.company = line_referential.companies.find_by registration_number: source_vehicle_journey[:operator_id]
        vehicle_journey.time_table_ids = @time_tables.delete(source_vehicle_journey[:object_id])
      end
      add_stop_points_to_vehicle_journey(vehicle_journey, source_vehicle_journey[:vehicle_journey_at_stop], source_vehicle_journey[:route_id])

      save_model vehicle_journey
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

  def add_stop_points_to_vehicle_journey(vehicle_journey, vehicle_journey_at_stops, route_object_id)
    vehicle_journey_at_stops = make_enum vehicle_journey_at_stops

    vehicle_journey.vehicle_journey_at_stops.destroy_all

    vehicle_journey_at_stops.sort_by{|i| i[:order]}.each do |source_vehicle_journey_at_stop|
      vehicle_journey.vehicle_journey_at_stops.build do |vehicle_journey_at_stop|
        vehicle_journey_at_stop.stop_point = @stop_points[route_object_id][source_vehicle_journey_at_stop[:stop_point_id]]
        vehicle_journey_at_stop.arrival_local_time = source_vehicle_journey_at_stop[:arrival_time]
        vehicle_journey_at_stop.departure_local_time = source_vehicle_journey_at_stop[:departure_time]
      end
    end
  end

  def route_wayback_mapping(source_value)
    {'a' => :outbound, 'aller' => :outbound, 'r' => 'inbound', 'retour' => 'inbound'}[source_value.downcase]
  end

  def build_object_from_nokogiri_element(element)
    out = { _node: element }
    element.children.each do |child|
      key = child.name.underscore.to_sym
      next if key == :text

      if child.children.count == 1 && child.children.last.node_type == Nokogiri::XML::Node::TEXT_NODE
        content = child.children.last.content
      else
        content = build_object_from_nokogiri_element(child)
      end

      if element.children.select{ |c| c.name == child.name }.count > 1
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
end
