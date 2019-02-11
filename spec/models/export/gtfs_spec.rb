RSpec.describe Export::Gtfs, type: [:model, :with_exportable_referential] do
  let(:gtfs_export) { create :gtfs_export, referential: referential, workbench: workbench, duration: 5}

  it "should create a default company and generate a message if the journey or its line doesn't have a company" do
    referential.switch do
      line = referential.lines.first
      line.company = nil
      line.save

      stop_areas = stop_area_referential.stop_areas.order("random()").limit(2)
      route = FactoryGirl.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
      journey_pattern = FactoryGirl.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
      vehicle_journey = FactoryGirl.create :vehicle_journey, journey_pattern: journey_pattern, company: nil

      gtfs_export.instance_variable_set('@journeys', Chouette::VehicleJourney.all)

      tmp_dir = Dir.mktmpdir

      agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')
      GTFS::Target.open(agencies_zip_path) do |target|
        expect { gtfs_export.export_companies_to target }.to change { Export::Message.count }.by(1)
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build agencies_zip_path, strict: false
      expect(source.agencies.length).to eq(1)
      agency = source.agencies.first
      expect(agency.id).to eq("chouette_default")
      expect(agency.timezone).to eq("Etc/GMT")

      # Test the line-company link
      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      GTFS::Target.open(lines_zip_path) do |target|
        gtfs_export.export_lines_to target
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build lines_zip_path, strict: false
      route = source.routes.first
      expect(route.agency_id).to eq("chouette_default")
    end
  end

  it "should set a default time zone and generate a message if the journey's company doesn't have one" do
    referential.switch do
      company.time_zone = nil
      company.save

      line = referential.lines.first
      stop_areas = stop_area_referential.stop_areas.order("random()").limit(2)
      route = FactoryGirl.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
      journey_pattern = FactoryGirl.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
      vehicle_journey = FactoryGirl.create :vehicle_journey, journey_pattern: journey_pattern, company: company

      gtfs_export.instance_variable_set('@journeys', Chouette::VehicleJourney.all)

      tmp_dir = Dir.mktmpdir

      agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')
      GTFS::Target.open(agencies_zip_path) do |target|
        expect { gtfs_export.export_companies_to target }.to change { Export::Message.count }.by(1)
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build agencies_zip_path, strict: false
      expect(source.agencies.length).to eq(1)
      agency = source.agencies.first
      expect(agency.id).to eq(company.registration_number)
      expect(agency.timezone).to eq("Etc/GMT")

      # Test the line-company link
      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      GTFS::Target.open(lines_zip_path) do |target|
        gtfs_export.export_lines_to target
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build lines_zip_path, strict: false
      route = source.routes.first
      expect(route.agency_id).to eq(company.registration_number)
    end
  end

  it "should correctly handle timezones" do
    referential.switch do
      company.time_zone = "Europe/Paris"
      company.save

      line = referential.lines.first
      stop_areas = stop_area_referential.stop_areas.order("random()").limit(2)
      route = FactoryGirl.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
      journey_pattern = FactoryGirl.create :journey_pattern, route: route, stop_points: route.stop_points.sample(2)
      vehicle_journey = FactoryGirl.create :vehicle_journey, journey_pattern: journey_pattern, company: company
      vehicle_journey.time_tables << (FactoryGirl.create :time_table)
      gtfs_export.instance_variable_set('@journeys', Chouette::VehicleJourney.all)

      tmp_dir = Dir.mktmpdir

      gtfs_export.export_to_dir tmp_dir

      # The processed export files are re-imported through the GTFS gem
      stop_times_zip_path = File.join(tmp_dir, "#{gtfs_export.zip_file_name}.zip")
      source = GTFS::Source.build stop_times_zip_path, strict: false

      vehicle_journey_at_stops = vehicle_journey.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }
      expect(source.stop_times.length).to eq(vehicle_journey_at_stops.length)

      random_vehicle_journey_at_stop = vehicle_journey_at_stops.sample
      stop_time = source.stop_times.detect{|stop_time| stop_time.arrival_time == GTFS::Time.format_datetime(random_vehicle_journey_at_stop.arrival_time, random_vehicle_journey_at_stop.arrival_day_offset, 'Europe/Paris') }
      expect(stop_time).not_to be_nil
      expect(stop_time.departure_time).to eq(GTFS::Time.format_datetime(random_vehicle_journey_at_stop.departure_time, random_vehicle_journey_at_stop.departure_day_offset, 'Europe/Paris'))
    end
  end

  context 'with journeys' do
    include_context 'with exportable journeys'

    it "should correctly export data as valid GTFS output" do
      # Create context for the tests
      selected_vehicle_journeys = []
      selected_stop_areas_hash = {}
      date_range = nil

      referential.switch do
        date_range = gtfs_export.date_range
        selected_vehicle_journeys = Chouette::VehicleJourney.with_matching_timetable date_range
        gtfs_export.instance_variable_set('@journeys', selected_vehicle_journeys)
      end

      tmp_dir = Dir.mktmpdir

      ################################
      # Test (1) agencies.txt export
      ################################

      agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')

      referential.switch do
        GTFS::Target.open(agencies_zip_path) do |target|
          gtfs_export.export_companies_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build agencies_zip_path, strict: false
        expect(source.agencies.length).to eq(1)
        agency = source.agencies.first
        expect(agency.id).to eq(company.registration_number)
        expect(agency.name).to eq(company.name)
      end

      ################################
      # Test (2) stops.txt export
      ################################

      stops_zip_path = File.join(tmp_dir, '/test_stops.zip')

      # Fetch the expected exported stop_areas
      referential.switch do
        selected_vehicle_journeys.each do |vehicle_journey|
            vehicle_journey.route.stop_points.each do |stop_point|
              (selected_stop_areas_hash[stop_point.stop_area.id] = stop_point.stop_area) if (stop_point.stop_area && stop_point.stop_area.commercial? && !selected_stop_areas_hash[stop_point.stop_area.id])
            end
        end
        selected_stop_areas = []
        selected_stop_areas = gtfs_export.export_stop_areas_recursively(selected_stop_areas_hash.values)

        GTFS::Target.open(stops_zip_path) do |target|
          # reset export sort variable
          gtfs_export.instance_variable_set('@stop_area_stop_hash', {})
          gtfs_export.export_stop_areas_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build stops_zip_path, strict: false

        # Same size
        expect(source.stops.length).to eq(selected_stop_areas.length)
        # Randomly pick a stop_area and find the correspondant stop exported in GTFS
        random_stop_area = selected_stop_areas.sample

        # Find matching random stop in exported stops.txt file
        random_gtfs_stop = source.stops.detect {|e| e.id == (random_stop_area.registration_number.presence || random_stop_area.object_id)}
        expect(random_gtfs_stop).not_to be_nil
        expect(random_gtfs_stop.name).to eq(random_stop_area.name)
        expect(random_gtfs_stop.location_type).to eq(random_stop_area.area_type == 'zdlp' ? '1' : '0')
        # Checks if the parents are similar
        expect(random_gtfs_stop.parent_station).to eq(((random_stop_area.parent.registration_number.presence || random_stop_area.parent.object_id) if random_stop_area.parent))
      end

      ################################
      # Test (3) lines.txt export
      ################################

      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      referential.switch do
        GTFS::Target.open(lines_zip_path) do |target|
          gtfs_export.export_lines_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build lines_zip_path, strict: false
        selected_routes = {}
        selected_vehicle_journeys.each do |vehicle_journey|
          selected_routes[vehicle_journey.route.line.id] = vehicle_journey.route.line
        end

        expect(source.routes.length).to eq(selected_routes.length)
        route = source.routes.first
        line = referential.lines.first

        expect(route.id).to eq(line.registration_number)
        expect(route.agency_id).to eq(line.company.registration_number)
        expect(route.long_name).to eq(line.published_name)
        expect(route.short_name).to eq(line.number)
        expect(route.type).to eq(gtfs_export.gtfs_line_type line)
        expect(route.desc).to eq(line.comment)
        expect(route.url).to eq(line.url)
      end

      ####################################################
      # Test (4) calendars.txt and calendar_dates.txt export #
      ####################################################

      calendars_zip_path = File.join(tmp_dir, '/test_calendars.zip')

      referential.switch do
        GTFS::Target.open(calendars_zip_path) do |target|
          gtfs_export.export_time_tables_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build calendars_zip_path, strict: false

        # Get VJ merged periods
        periods = []
        selected_vehicle_journeys.each do |vehicle_journey|
          periods << vehicle_journey.flattened_circulation_periods.select{|period| period.range & date_range}
        end

        periods = periods.flatten.uniq

        # Same size
        expect(source.calendars.length).to eq(periods.length)
        # Randomly pick a time_table_period and find the correspondant calendar exported in GTFS
        random_period = periods.sample
        # Find matching random stop in exported stops.txt file
        random_gtfs_calendar = source.calendars.detect do |e|
          e.service_id == random_period.object_id
          e.start_date == (random_period.period_start.strftime('%Y%m%d'))
          e.end_date == (random_period.period_end.strftime('%Y%m%d'))

          e.monday == (random_period.monday ? "1" : "0")
          e.tuesday == (random_period.tuesday ? "1" : "0")
          e.wednesday == (random_period.wednesday ? "1" : "0")
          e.thursday == (random_period.thursday ? "1" : "0")
          e.friday == (random_period.friday ? "1" : "0")
          e.saturday == (random_period.saturday ? "1" : "0")
          e.sunday == (random_period.sunday ? "1" : "0")
        end

        expect(random_gtfs_calendar).not_to be_nil
        expect((random_period.period_start..random_period.period_end).overlaps?(date_range.begin..date_range.end)).to be_truthy

        # TO MODIFY IF NEEDED : the method vehicle_journeys#flattened_circulation_periods casts any time_table_dates into a single day period/calendar.
        # Thus, for the moment, no time_table_dates / calendar_dates.txt 'll be exported
        # Test time_table_dates
        # vj_dates = selected_vehicle_journeys.map{|vj| vj.time_tables.map {|time_table|time_table.dates}}.flatten.uniq.select {|date| (date_range.begin..date_range.end) === date.date}
        #
        # vj_dates.length.should eq(source.calendar_dates.length)
        # vj_dates.each do |date|
        #   period = nil
        #   if date.in_out
        #     period = date.time_table.periods.first
        #   else
        #     period = date.time_table.periods.detect {|period| (period.period_start..period.period_end) === date.date}
        #   end
        #   period.should_not be_nil
        #
        #   calendar_date = source.calendar_dates.detect {|c| c.service_id == (period.id.to_s) && c.date == date.date.strftime('%Y%m%d')}
        #   calendar_date.should_not be_nil
        #   calendar_date.exception_type.should eq(date.in_out ? '1' : '2')
        # end

        ################################
        # Test (5) trips.txt export
        ################################

        targets_zip_path = File.join(tmp_dir, '/test_trips.zip')

        GTFS::Target.open(targets_zip_path) do |target|
          gtfs_export.export_vehicle_journeys_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build targets_zip_path, strict: false

        # Get VJ merged periods
        vj_periods = []
        selected_vehicle_journeys.each do |vehicle_journey|
          vehicle_journey.flattened_circulation_periods.select{|period| period.range & date_range}.each do |period|
            vj_periods << [period,vehicle_journey]
          end
        end

        # Same size
        expect(source.trips.length).to eq(vj_periods.length)

        # Randomly pick a vehicule_journey / period couple and find the correspondant trip exported in GTFS
        random_vj_period = vj_periods.sample

        # Find matching random stop in exported trips.txt file
        random_gtfs_trip = source.trips.detect {|t| t.service_id == random_vj_period.first.object_id.to_s && t.route_id == random_vj_period.last.route.line.registration_number.to_s}
        expect(random_gtfs_trip).not_to be_nil

        ################################
        # Test (6) stop_times.txt export
        ################################

        stop_times_zip_path = File.join(tmp_dir, '/stop_times.zip')
        GTFS::Target.open(stop_times_zip_path) do |target|
          gtfs_export.export_vehicle_journey_at_stops_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build stop_times_zip_path, strict: false

        expected_stop_times_length = vj_periods.map{|vj| vj.last.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }}.flatten.length

        # Same size
        expect(source.stop_times.length).to eq(expected_stop_times_length)

        # Count the number of stop_times generated by a random VJ and period couple (sop_times depends on a vj, a period and a stop_area)
        vehicle_journey_at_stops = random_vj_period.last.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }

        # Fetch all the stop_times entries exported in GTFS related to the trip (matching the previous VJ / period couple)
        stop_times = source.stop_times.select{|stop_time| stop_time.trip_id == random_gtfs_trip.id }

        # Same size 2
        expect(stop_times.length).to eq(vehicle_journey_at_stops.length)

        # A random stop_time is picked
        random_vehicle_journey_at_stop = vehicle_journey_at_stops.sample
        stop_time = stop_times.detect{|stop_time| stop_time.arrival_time == GTFS::Time.format_datetime(random_vehicle_journey_at_stop.arrival_time, random_vehicle_journey_at_stop.arrival_day_offset) }
        expect(stop_time).not_to be_nil
        expect(stop_time.departure_time).to eq(GTFS::Time.format_datetime(random_vehicle_journey_at_stop.departure_time, random_vehicle_journey_at_stop.departure_day_offset))
      end
    end
  end
end
