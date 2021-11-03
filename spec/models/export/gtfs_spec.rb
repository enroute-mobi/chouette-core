RSpec.describe Export::Gtfs, type: [:model, :with_exportable_referential] do
  let(:gtfs_export) { create :gtfs_export, referential: exported_referential, workbench: workbench, duration: 5, prefer_referent_stop_area: true}

  describe 'Company Part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:index) { export.index }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup, referential: context.referential }

    let(:part) do
      Export::Gtfs::Companies.new export
    end

    let(:context) do
      Chouette.create do
        line_provider :first do
          company :c1, registration_number: "1", time_zone: "Europe/Paris"
          line :l1, company: :c1
        end
        line_provider :other do
          company :c2, registration_number: "1", time_zone: "Europe/Paris"
          line :l2, company: :c2
        end

        route line: :l1 do
          vehicle_journey
        end
        route line: :l2 do
          vehicle_journey
        end
      end
    end

    let(:first_company) {context.company(:c1)}
    let(:second_company) {context.company(:c2)}

    before do
      context.referential.switch
    end

    it "should use companies objectid when their registration_number is not unique" do
      part.export!
      expect(export.target.agencies.map(&:id)).to match_array([first_company.objectid, second_company.objectid])
    end
  end

  describe 'StopArea Part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:index) { export.index }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup, referential: context.referential }

    let(:part) do
      Export::Gtfs::StopAreas.new export
    end

    let(:context) do
      Chouette.create do
        stop_area_provider :first do
          stop_area :sa1, registration_number: "1"
        end
        stop_area_provider :other do
          stop_area :sa2, registration_number: "1"
        end

        referential
      end
    end

    let(:first_stop_area) {context.stop_area(:sa1)}
    let(:second_stop_area) {context.stop_area(:sa2)}

    before do
      context.referential.switch
    end

    it "should use stop_areas objectid when their registration_number is not unique" do
      part.export!
      expect(export.target.stops.map(&:id)).to match_array([first_stop_area.objectid, second_stop_area.objectid])
    end

  end

  describe "Stop Area Decorator" do
    let(:stop_area) { Chouette::StopArea.new }
    let(:decorator) { Export::Gtfs::StopAreas::Decorator.new stop_area }

    describe "#stop_id" do
      subject { decorator.stop_id }

      context "when the Stop Area registration number is 'test" do
        before { stop_area.registration_number = "test" }
        it { is_expected.to be(stop_area.registration_number) }
      end

      context "when the Stop Area registration number an empty string" do
        before do
          stop_area.registration_number = ""
          stop_area.objectid = "chouette:StopArea:test:LOC"
        end

        it "is expected to be the objectid" do
          is_expected.to eq(stop_area.objectid)
        end
      end

      context "when the Stop Area registration number is nil" do
         before do
          stop_area.registration_number = ""
          stop_area.objectid = "chouette:StopArea:test:LOC"
        end

        it "is expected to be the objectid" do
          is_expected.to eq(stop_area.objectid)
        end
      end
    end

    describe "#gtfs_platform_code" do
      subject { decorator.gtfs_platform_code }
      context "when public code is nil" do
        before { stop_area.public_code = nil }
        it { is_expected.to be_nil }
      end
      context "when public code is ''" do
        before { stop_area.public_code = '' }
        it { is_expected.to be_nil }
      end
      context "when public code is 'dummy" do
        before { stop_area.public_code = 'dummy' }
        it { is_expected.to eq('dummy') }
      end
    end

    describe "stop_attributes" do
      subject { decorator.stop_attributes }
      context "when gtfs_platform_code is 'dummy'" do
        before { allow(decorator).to receive(:gtfs_platform_code).and_return("dummy") }
        it { is_expected.to include(platform_code: 'dummy')}
      end
    end
  end

  describe 'Line Part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:index) { export.index }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup, referential: context.referential }

    let(:part) do
      Export::Gtfs::Lines.new export
    end

    let(:context) do
      Chouette.create do
        line_provider :first do
          company :c1, registration_number: "r1"
          line :l1, company: :c1, registration_number: "1"
        end
        line_provider :other do
          company :c2, registration_number: "r2"
          line :l2, company: :c2, registration_number: "1"
        end

        referential lines: [:l1, :l2]
      end
    end

    let(:first_line) {context.line(:l1)}
    let(:first_company) {first_line.company}
    let(:second_line) {context.line(:l2)}
    let(:second_company) {second_line.company}

    before do
      context.referential.switch
      index.register_agency_id(first_company, first_company.registration_number)
      index.register_agency_id(second_company, second_company.registration_number)
    end

    it "should use lines objectid when their registration_number is not unique" do
      part.export!
      expect(export.target.routes.map(&:id)).to match_array([first_line.objectid, second_line.objectid])
    end
  end

  describe "Line Decorator" do

    let(:line) { Chouette::Line.new }
    let(:decorator) { Export::Gtfs::Lines::Decorator.new line }

    describe "#route_id" do
      subject { decorator.route_id }

      context "when the Line registration_number is 'test" do
        before { line.registration_number = "test" }
        it { is_expected.to be(line.registration_number) }
      end

      context "when the Line registration_number an empty string" do
        before do
          line.registration_number = ""
          line.objectid = "chouette:Line:test:LOC"
        end

        it "is expected to be the objectid" do
          is_expected.to eq(line.objectid)
        end
      end

      context "when the Line registration_number is nil" do
         before do
          line.registration_number = ""
          line.objectid = "chouette:Line:test:LOC"
        end

        it "is expected to be the objectid" do
          is_expected.to eq(line.objectid)
        end
      end
    end

    describe "route_type" do

      expected_route_types = {
        tram: 0,
        metro: 1,
        rail: 2,
        bus: 3,
        water: 4,
        telecabin: 6,
        funicular: 7,
        coach: 200,
        air: 1100,
        taxi: 1500,
        hireCar: 1506
      }

      TransportModeEnumerations.transport_modes.each do |transport_mode|
        expected_route_type = expected_route_types[transport_mode]
        if expected_route_type
          it "uses value #{expected_route_type.inspect} for transport mode #{transport_mode}" do
            line.transport_mode = transport_mode
            expect(decorator.route_type).to eq(expected_route_type)
          end
        else
          it "doesn't support unexpected transport mode #{transport_mode}" do
            fail "No GTFS Route type expected for transport mode #{transport_mode}"
          end
        end
      end

      context "when line is flexible" do
        it "uses value 715 (Demand and Response Bus Service)" do
          line.flexible_service = true
          expect(decorator.route_type).to eq(715)
        end
      end

    end

    describe "route_long_name" do

      it "uses line published_name when available" do
        line.published_name = "test"
        expect(decorator.route_long_name).to eq(line.published_name)
      end

      it "uses line name when published_name is not available" do
        line.published_name = nil
        line.name = "test"
        expect(decorator.route_long_name).to eq(line.name)
      end

      it "is nil if the candidate value is the route_short_name value" do
        allow(decorator).to receive(:route_short_name).and_return("test")

        line.published_name = decorator.route_short_name
        expect(decorator.route_long_name).to eq(nil)

        line.published_name = nil
        line.name = decorator.route_short_name
        expect(decorator.route_long_name).to eq(nil)
      end

    end

    describe "route attributes" do

      %i{short_name long_name}.each do |route_attribute|
        attribute = "route_#{route_attribute}".to_sym

        it "uses #{attribute} method to fill associated attribute (#{route_attribute})" do
          allow(decorator).to receive(attribute).and_return("test")
          route_attribute = attribute.to_s.gsub(/^route_/,'').to_sym
          expect(decorator.route_attributes[route_attribute]).to eq(decorator.send(attribute))
        end
      end

      %i{url color text_color}.each do |attribute|
        it "uses line #{attribute} to fill the same route attribute" do
          allow(line).to receive(attribute).and_return("test")
          expect(decorator.route_attributes[attribute]).to eq(line.send(attribute))
        end
      end

    end
  end

  describe "TimeTable Decorator" do
    context "with a nil date_range" do
      context 'with one period' do
        let(:context) do
          Chouette::Factory.create do
            time_table dates_excluded: Time.zone.today, dates_included: Time.zone.tomorrow
          end
        end

        let(:time_table) { context.time_table }
        let(:decorator) { Export::Gtfs::TimeTables::TimeTableDecorator.new time_table }

        it "should return one period" do
          expect(decorator.periods.length).to eq 1
        end

        it "should return two dates" do
          expect(decorator.dates.length).to eq 2
        end

        it "should return a calendar with default service_id" do
          c = decorator.calendars
          expect(c.count).to eq 1
          expect(c.first[:service_id]).to eq decorator.default_service_id
        end

        it "should return calendar_dates with correct service_id" do
          cd = decorator.calendar_dates
          expect(cd.count).to eq 2
          cd.each do |date|
            expect(date[:service_id]).to eq decorator.default_service_id
          end
        end
      end

      context 'with multiple periods' do
        let(:context) do
          Chouette::Factory.create do
            time_table periods: [ Time.zone.today..Time.zone.today+1, Time.zone.today+3..Time.zone.today+4 ]
          end
        end

        let(:time_table) { context.time_table }
        let(:decorator) { Export::Gtfs::TimeTables::TimeTableDecorator.new time_table }

        it "should return two periods" do
          expect(decorator.periods.length).to eq 2
        end

        it "should return calendars with correct service_id" do
          c = decorator.calendars
          expect(c.count).to eq 2
          expect(c.first[:service_id]).to eq decorator.default_service_id
          expect(c.last[:service_id]).to eq time_table.periods.last.id
        end
      end
    end

    context "with a non nil date_range" do
      let(:context) do
        Chouette::Factory.create do
          time_table dates_excluded: Time.zone.today+1,
                     dates_included: 1.month.from_now.to_date,
                     periods: [ Time.zone.today..Time.zone.today+2, Time.zone.today+5..Time.zone.today+6 ]
        end
      end

      let(:time_table) { context.time_table }
      let(:decorator) { Export::Gtfs::TimeTables::TimeTableDecorator.new time_table, Time.zone.tomorrow..Time.zone.tomorrow+1 }

      it "should return one period" do
        expect(decorator.periods.length).to eq 1
      end

      it "should return one date" do
        expect(decorator.dates.length).to eq 1
      end
    end
  end

  describe "VehicleJourneyAtStop Part" do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup }

    let(:part) do
      Export::Gtfs::VehicleJourneyAtStops.new export
    end

    let(:context) do
      Chouette.create do
        stop_area :non_commercial, kind: 'non_commercial', area_type: 'deposit'

        stop_area :referent, kind: 'non_commercial', area_type: 'deposit'
        stop_area :with_referent_non_commercial, referent: :referent

        route with_stops: false do
          stop_point :departure
          stop_point :stop_non_commercial, stop_area: :non_commercial
          stop_point :stop_with_referent_non_commercial, stop_area: :with_referent_non_commercial
          stop_point :arrival

          vehicle_journey
        end
      end
    end

    before do
      context.referential.switch
    end

    context "when prefer_referent_stop_area is true" do
      before { export.options["prefer_referent_stop_area"] = true }

      it "ignore Vehicle Journey At Stops associated to a non commercial Referent Stop Area" do
        expect(part.vehicle_journey_at_stops.length).to eq(2)
      end
    end

    context "when prefer_referent_stop_area is false" do
      before { export.options["prefer_referent_stop_area"] = false }

      it "ignore Vehicle Journey At Stops associated to a non commercial Stop Area" do
        expect(part.vehicle_journey_at_stops.length).to eq(3)
      end
    end

  end

  describe "VehicleJourneyAtStop Decorator" do

    let(:vehicle_journey) { Chouette::VehicleJourney.new }
    let(:vehicle_journey_at_stop) { Chouette::VehicleJourneyAtStop.new(vehicle_journey: vehicle_journey) }
    let(:vjas_raw_hash) {
      {
        departure_time: vehicle_journey_at_stop.departure_time,
        arrival_time: vehicle_journey_at_stop.arrival_time,
        departure_day_offset: vehicle_journey_at_stop.departure_day_offset,
        arrival_day_offset: vehicle_journey_at_stop.arrival_day_offset,
        vehicle_journey_id: vehicle_journey_at_stop.vehicle_journey_id,
        stop_area_id: vehicle_journey_at_stop.stop_area_id,
        parent_stop_area_id: vehicle_journey_at_stop.stop_point&.stop_area_id,
        position: vehicle_journey_at_stop.stop_point&.position,
        for_alighting: vehicle_journey_at_stop.stop_point&.for_alighting,
        for_boarding: vehicle_journey_at_stop.stop_point&.for_boarding,
      }.stringify_keys
    }

    let(:index) { double }
    let(:decorator) do
      Export::Gtfs::VehicleJourneyAtStops::Decorator.new vjas_raw_hash, index: index
    end

    let(:time_zone) { "Europe/Paris" }

    describe "time zone" do

      it "uses time zone associated with the VehicleJourney in the index" do
        vehicle_journey_at_stop.vehicle_journey_id = 42
        expect(index).to receive(:vehicle_journey_time_zone).
                           with(vehicle_journey_at_stop.vehicle_journey_id).
                           and_return(time_zone)
        expect(decorator.time_zone).to be(time_zone)
      end

      it "returns nil if the VehicleJourney isn't associated to a time zone" do
        vehicle_journey_at_stop.vehicle_journey_id = 42
        expect(index).to receive(:vehicle_journey_time_zone).
                           with(vehicle_journey_at_stop.vehicle_journey_id).
                           and_return(nil)
        expect(decorator.time_zone).to be(nil)
      end

    end

    %w{arrival departure}.each do |state|
      describe "#{state}_time_of_day" do

        subject { decorator.send "#{state}_time_of_day" }

        context "when #{state}_time is nil" do
          before { allow(decorator).to receive("#{state}_time").and_return(nil) }

          it { is_expected.to be_nil }
        end

        context "when #{state}_time is defined" do
          it "uses #{state}_time to create a TimeOfDay" do
            allow(decorator).to receive("#{state}_time").and_return("14:00")
            is_expected.to eq(TimeOfDay.new(14))
          end

          it "uses #{state}_day_offset to create TimeOfDay" do
            allow(decorator).to receive("#{state}_time").and_return("14:00")
            allow(decorator).to receive("#{state}_day_offset").and_return(1)

            is_expected.to eq(TimeOfDay.new(14, day_offset: 1))
          end
        end

      end

      describe "#{state}_local_time_of_day" do

        subject { decorator.send "#{state}_local_time_of_day" }

        context "when #{state}_time is nil" do
          before { allow(decorator).to receive("#{state}_time").and_return(nil) }
          it { is_expected.to be_nil }
        end

        context "when #{state}_time_of_day is nil" do
          before { allow(decorator).to receive("#{state}_time_of_day").and_return(nil) }
          it { is_expected.to be_nil }
        end

        context "when #{state}_time_of_day is defined" do

          let(:time_of_day) { TimeOfDay.new(14) }
          before { allow(decorator).to receive("#{state}_time_of_day").and_return(time_of_day) }

          context "when time_zone is defined" do

            let(:time_zone) { "Europe/Paris" }
            before { allow(decorator).to receive(:time_zone).and_return(time_zone) }

            it "returns #{state}_time_of_day with time_zone offset" do
              is_expected.to eq(time_of_day.with_utc_offset(1.hour))
            end
          end

          context "when time_zone is not defined" do
            before { allow(decorator).to receive(:time_zone).and_return(nil) }

            it "returns #{state}_time_of_day unchanged" do
              is_expected.to eq(time_of_day)
            end
          end

        end

      end

      describe "stop_time_#{state}_time" do

        subject { decorator.send "stop_time_#{state}_time" }

        context "when #{state}_local_time_of_day is nil" do
          before { allow(decorator).to receive("#{state}_time_of_day").and_return(nil) }
          it { is_expected.to be_nil }
        end

        context "when #{state}_local_time_of_day is defined" do

          let(:time_of_day) { TimeOfDay.new(14) }
          before { allow(decorator).to receive("#{state}_local_time_of_day").and_return(time_of_day) }

          it "returns a GTFS::Time string representation based on #{state}_local_time_of_day value" do
            is_expected.to eq("14:00:00")
          end

        end

      end

    end

    describe "stop_area_id" do

      let(:stop_point) { double stop_area_id: 42, position: 21, for_alighting:'', for_boarding:'' }

      context "when VehicleJourneyAtStop defines a specific stop" do

        before { vehicle_journey_at_stop.stop_area_id = 42 }

        it "uses the VehicleJourneyAtStop#stop_area_id" do
          expect(decorator.stop_area_id).to eq(vehicle_journey_at_stop.stop_area_id)
        end

      end

      it "uses the Stop Point stop_area_id" do
        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.stop_area_id).to eq(stop_point.stop_area_id)
      end

    end

    describe "position" do

      let(:stop_point) { double stop_area_id: 21, position: 42, for_alighting:'', for_boarding:'' }

      it "uses the Stop Point position" do
        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.position).to eq(stop_point.position)
      end

    end

    describe "drop_off_type" do

      let(:stop_point) { double stop_area_id: 21, position: 42, for_boarding:''}

      it 'return the correct value when for_alighting is forbidden' do
        allow(stop_point).to receive(:for_alighting).and_return('forbidden')

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.drop_off_type).to eq(1)
      end

      it 'return the correct value when for_alighting is not forbidden' do
        allow(stop_point).to receive(:for_alighting).and_return(nil)

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.drop_off_type).to eq(nil)
      end

    end

    describe "pickup_type" do

      let(:stop_point) { double stop_area_id: 21, position: 42, for_alighting:''}

      it 'return the correct value when for_boarding is forbidden' do
        allow(stop_point).to receive(:for_boarding).and_return('forbidden')

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.pickup_type).to eq(1)
      end

      it 'return the correct value when for_boarding is not forbidden' do
        allow(index).to receive(:pickup_type).with(vehicle_journey_at_stop.vehicle_journey.id).and_return(nil)
        allow(stop_point).to receive(:for_boarding).and_return(nil)

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.pickup_type).to eq(0)
      end

      it 'return the correct value when for_boarding is not forbidden and vehicle_journey is registered in the index' do
        allow(index).to receive(:pickup_type).with(vehicle_journey_at_stop.vehicle_journey.id).and_return(true)

        allow(stop_point).to receive(:for_boarding).and_return(nil)

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.pickup_type).to eq(2)
      end

    end


    describe "stop_time_stop_id" do

      it "uses stop_id associated to the stop_area_id in the index" do
        allow(decorator).to receive(:stop_area_id).and_return(42)
        expect(index).to receive(:stop_id).
                           with(decorator.stop_area_id).
                           and_return("test")

        expect(decorator.stop_time_stop_id).to eq("test")
      end

    end

    describe "stop_time attributes" do

      before do
        allow(index).to receive_messages(pickup_type: 0)
        allow(decorator).to receive_messages(time_zone: nil, position: 42, stop_time_stop_id: "test")
        vehicle_journey_at_stop.departure_time =
          vehicle_journey_at_stop.arrival_time = Time.parse("23:00")
      end

      %i{departure_time arrival_time stop_id}.each do |stop_time_attribute|
        attribute = "stop_time_#{stop_time_attribute}".to_sym
        it "uses #{attribute} method to fill associated attribute (#{stop_time_attribute})" do
          allow(decorator).to receive(attribute).and_return("test")
          stop_time_attribute = attribute.to_s.gsub(/^stop_time_/,'').to_sym
          expect(decorator.stop_time_attributes[stop_time_attribute]).to eq(decorator.send(attribute))
        end
      end

      it "uses position to fill the same stop_sequence attribute" do
        allow(decorator).to receive(:position).and_return(42)
        expect(decorator.stop_time_attributes[:stop_sequence]).to eq(decorator.position)
      end

    end

  end

  describe 'VehicleJourneys Part' do

    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:index) { export.index }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup }

    let(:part) do
      Export::Gtfs::VehicleJourneys.new export
    end

    let(:context) do
      Chouette.create do
        time_table :default
        vehicle_journey time_tables: [:default], flexible_service: true
        vehicle_journey time_tables: [:default], flexible_service: false
      end
    end

    let(:time_table) { context.time_table(:default) }
    let(:vehicle_journeys) { context.vehicle_journeys }

    before do
      context.referential.switch
      index.register_service_ids time_table, [time_table.objectid]
    end

    it "registers the GTFS Trip identifiers used for each VehicleJourney" do
      part.export!
      vehicle_journeys.each do |vehicle_journey|
        expect(index.trip_ids(vehicle_journey.id)).to eq([vehicle_journey.objectid])
      end
    end

    it "registers the GTFS pickup_type for each VehicleJourney" do
      part.export!
      vehicle_journeys.each do |vehicle_journey|
        expect(index.pickup_type(vehicle_journey.id)).to eq(vehicle_journey.flexible_service)
      end
    end

    context "when the Line has flexible service" do
      it "registers the GTFS pickup_type according to the Line" do
        vehicle_journey = vehicle_journeys.first
        vehicle_journey.line.update flexible_service: true

        part.export!

        expect(index.pickup_type(vehicle_journey.id)).to be_truthy
      end
    end

  end

  describe 'VehicleJourney Decorator' do

    let(:vehicle_journey) { Chouette::VehicleJourney.new }
    let(:index) { Export::Gtfs::Index.new }
    let(:resource_code_space) { double }
    let(:decorator) do
      Export::Gtfs::VehicleJourneys::Decorator.new vehicle_journey, index: index, code_provider: resource_code_space
    end

    describe '#route_id' do

      subject { decorator.route_id }

      let(:indexed_route_id) { double 'GTFS route_id associated to the VehicleJourney line' }

      before do
        line = Chouette::Line.new(id: rand(100))
        vehicle_journey.route = Chouette::Route.new(line_id: line.id)
        index.register_route_id line, indexed_route_id
      end

      it { is_expected.to be(indexed_route_id) }

    end

    describe '#trip_id' do

      subject { decorator.trip_id(suffix) }

      let(:suffix) { 'suffix' }
      let(:base_trip_id) { 'base_trip_id' }
      let(:suffixed_base_trip_id) { "#{base_trip_id}-#{suffix}" }

      before do
        allow(decorator).to receive(:base_trip_id).and_return(base_trip_id)
      end

      context "when several service identifiers are associated" do

        before { allow(decorator).to receive(:single_service_id?).and_return(false) }

        it "uses the base trip id with the given suffix" do
          is_expected.to eq(suffixed_base_trip_id)
        end

      end

      context "when a single service identifier is associated" do

        before do
          allow(decorator).to receive(:single_service_id?).and_return(true)
        end

        it "uses the raw base trip id" do
          is_expected.to eq(base_trip_id)
        end

      end

      describe '#trip_attributes' do

        subject { decorator.trip_attributes(service_id) }
        let(:service_id) { 'service_id' }

        it 'uses route_id as attribute' do
          allow(decorator).to receive(:route_id).and_return(rand(100))
          is_expected.to include(route_id: decorator.route_id)
        end

        it 'uses the given service_id as attribute' do
          is_expected.to include(service_id: service_id)
        end

        it 'uses trip_id (with given service_id) as id attribute' do
          trip_id = rand(100)
          allow(decorator).to receive(:trip_id).with(service_id).and_return(trip_id)
          is_expected.to include(id: trip_id)
        end

        it 'uses published_journey_name as short_name attribute' do
          vehicle_journey.published_journey_name = 'published_journey_name'
          is_expected.to include(short_name: vehicle_journey.published_journey_name)
        end

        it 'uses direction_id as attribute' do
          allow(decorator).to receive(:direction_id).and_return(0)
          is_expected.to include(direction_id: decorator.direction_id)
        end

        it 'uses shape_id as attribute' do
          allow(decorator).to receive(:shape_id).and_return(42)
          is_expected.to include(shape_id: decorator.gtfs_shape_id)
        end

      end

    end

    describe '#gtfs_code' do

      subject { decorator.gtfs_code }
      before { allow(resource_code_space).to receive(:unique_code).and_return(code) }

      describe 'when the VehicleJourney has no code' do
        let(:code) { nil }
        it { is_expected.to be_nil }
      end

      describe 'when the VehicleJourney has an unique code' do
        let(:code) { 'unique_code' }
        it { is_expected.to eq(code) }
      end

    end

    describe '#base_trip_id' do

      subject { decorator.base_trip_id }

      before { vehicle_journey.objectid = 'test' }

      context 'when gtfs_code is nil' do

        before { allow(decorator).to receive(:gtfs_code).and_return(nil) }

        it "returns VehicleJourney objectid" do
          is_expected.to eq(vehicle_journey.objectid)
        end

      end

      context 'when gtfs_code has a value' do

        before { allow(decorator).to receive(:gtfs_code).and_return('test') }

        it "returns this gtfs_code" do
          is_expected.to eq(decorator.gtfs_code)
        end

      end

    end

    describe '#service_ids' do

      subject { decorator.service_ids }

      before do
        decorator.index.register_service_ids double(id: 1), %w{a b c}.to_set
        decorator.index.register_service_ids double(id: 2), %w{d e f}.to_set

        allow(decorator).to receive(:time_table_ids).and_return([1, 2])
      end

      it "returns all the GTFS service identifiers associated to Vehicle Journey TimeTable identifiers" do
        is_expected.to match_array(%w{a b c d e f}.to_set)
      end

    end

    describe '#single_service_id?' do

      subject { decorator.single_service_id? }

      before { allow(decorator).to receive(:service_ids).and_return(service_ids.to_set) }

      context 'when there is a single value returned by service_ids' do
        let(:service_ids) { %w{a} }

        it { is_expected.to be_truthy }
      end

      context 'when there are several values returned by service_ids' do
        let(:service_ids) { %w{a b} }

        it { is_expected.to be_falsy }
      end

    end

    describe '#direction_id' do

      subject { decorator.direction_id }

      before do
        vehicle_journey.route = Chouette::Route.new wayback: wayback
      end

      context "when route wayback is outbound" do
        let(:wayback) { Chouette::Route.outbound }
        it { is_expected.to eq(0) }
      end

      context "when route wayback is inbound" do
        let(:wayback) { Chouette::Route.inbound }
        it { is_expected.to eq(1) }
      end

    end

    describe '#shape_id' do

      subject { decorator.gtfs_shape_id }

      context "when a Shape is associated to the Journey Pattern" do
        let(:indexed_shape_id) { double 'GTFS shape_id associated to the JourneyPattern Shape' }

        before do
          shape = Shape.new id: 42
          vehicle_journey.journey_pattern = Chouette::JourneyPattern.new(shape_id: shape.id)
          index.register_shape_id shape, indexed_shape_id
        end

        it { is_expected.to be(indexed_shape_id) }
      end

      context "when no Shape is associated to the Journey Pattern" do
        before do
          vehicle_journey.journey_pattern = Chouette::JourneyPattern.new
        end

        it { is_expected.to be_nil }
      end

    end

  end

  describe 'Shapes Part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup }

    let(:part) do
      Export::Gtfs::Shapes.new export
    end

    let(:context) do
      Chouette.create do
        shape
        shape

        referential
      end
    end

    let(:shapes) { context.shapes }

    it 'creates a GTFS Shape for each Shape' do
      part.export!

      shape_ids = export.target.shape_points.map(&:shape_id).uniq
      expect(shape_ids.count).to eq(shapes.count)
    end

    it 'creates a GTFS ShapePoint for each Shape geometry point' do
      part.export!

      gtfs_shape_points = export.target.shape_points
      shape_points = shapes.map { |shape| shape.geometry.points }.flatten

      expect(gtfs_shape_points.count).to eq(shape_points.count)
    end

    it 'registers the used GTFS Shape id for each Shape' do
      part.export!

      shapes.each do |shape|
        expect(export.index.shape_id(shape.id)).to be_present
      end
    end

    describe 'Decorator' do
      let(:shape) { Shape.new }
      let(:decorator) { Export::Gtfs::Shapes::Decorator.new shape, code_provider: code_provider }
      let(:code_provider) { double }

      describe '#gtfs_code' do
        subject { decorator.gtfs_code }

        it 'uses unique code from code provider' do
          expect(code_provider).to receive(:unique_code).with(decorator).and_return(unique_code = 'unique_code')
          is_expected.to eq(unique_code)
        end
      end

      describe '#gtfs_id' do
        subject { decorator.gtfs_id }

        context 'when the GTFS code is nil' do
          before { allow(decorator).to receive(:gtfs_code).and_return(nil) }
          it 'is the Shape uuid' do
            is_expected.to eq(shape.uuid)
          end
        end

        context 'when the GTFS code is defined' do
          before { allow(decorator).to receive(:gtfs_code).and_return('gtfs_code') }
          it 'is the GTFS code' do
            is_expected.to eq(decorator.gtfs_code)
          end
        end
      end

      describe '#gtfs_shape_points' do
        before { shape.geometry = 'LINESTRING(2.2945 48.8584,2.295 48.859)' }

        subject { decorator.gtfs_shape_points }

        it 'includes a GTFS::ShapePoint for each geometry point' do
          is_expected.to match_array([
            have_attributes(pt_lat: 48.8584, pt_lon: 2.2945),
            have_attributes(pt_lat: 48.859, pt_lon: 2.295)
          ])
        end
      end
    end
  end

  describe 'CodeSpaces' do

    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:code_space) { context.workgroup.code_spaces.default }
    let(:code_spaces) { Export::Gtfs::CodeSpaces.new code_space, scope: export_scope }

    before { context.referential.switch }

    describe "for Shapes" do

      let(:context) do
        Chouette.create do
          shape :first
          shape :second

          referential
        end
      end

      let(:resource) { code_spaces.shapes }

      let(:shape) { context.shape :first }
      let(:other_shape) { context.shape :second }

      describe '#unique_code' do
        subject { resource.unique_code shape }

        context 'when the Shape is several codes' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            shape.codes.create! code_space: code_space, value: '2'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape is no code' do
          before { shape.codes.delete_all }

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a code already used by another Vehicle Journey' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            other_shape.codes.create! code_space: code_space, value: '1'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a unique code' do
          let(:unique_code_value) { 'unique' }
          before do
            shape.codes.create! code_space: code_space, value: unique_code_value
          end

          it { is_expected.to eq(unique_code_value) }
        end

      end

    end

    describe "for Shapes" do

      let(:context) do
        Chouette.create do
          shape :first
          shape :second

          referential
        end
      end

      let(:resource) { code_spaces.shapes }

      let(:shape) { context.shape :first }
      let(:other_shape) { context.shape :second }

      describe '#unique_code' do
        subject { resource.unique_code shape }

        context 'when the Shape is several codes' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            shape.codes.create! code_space: code_space, value: '2'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape is no code' do
          before { shape.codes.delete_all }

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a code already used by another Shape' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            other_shape.codes.create! code_space: code_space, value: '1'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a unique code' do
          let(:unique_code_value) { 'unique' }
          before do
            shape.codes.create! code_space: code_space, value: unique_code_value
          end

          it { is_expected.to eq(unique_code_value) }
        end

      end

    end
  end

  describe '#worker_died' do

    it 'should set gtfs_export status to failed' do
      expect(gtfs_export.status).to eq("new")
      gtfs_export.worker_died
      expect(gtfs_export.status).to eq("failed")
    end
  end

  it "should create a default company and generate a message if the journey or its line doesn't have a company" do
    exported_referential.switch do
      exported_referential.lines.update_all company_id: nil
      line = exported_referential.lines.first

      stop_areas = stop_area_referential.stop_areas.order(Arel.sql('random()')).limit(2)
      route = FactoryBot.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
      journey_pattern = FactoryBot.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
      FactoryBot.create :vehicle_journey, journey_pattern: journey_pattern, company: nil

      gtfs_export.export_scope = Export::Scope::All.new(exported_referential)

      tmp_dir = Dir.mktmpdir

      agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')
      GTFS::Target.open(agencies_zip_path) do |target|
        gtfs_export.export_companies_to target
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build agencies_zip_path, strict: false
      expect(source.agencies.length).to eq(1)
      agency = source.agencies.first
      expect(agency.id).to eq("chouette_default")
      expect(agency.timezone).to eq("Etc/UTC")

      # Test the line-company link
      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      GTFS::Target.open(lines_zip_path) do |target|
        expect { gtfs_export.export_lines_to target }.to change { Export::Message.count }.by(2)
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build lines_zip_path, strict: false
      route = source.routes.first
      expect(route.agency_id).to eq("chouette_default")
    end
  end

  it "should set a default time zone and generate a message if the journey's company doesn't have one" do
    exported_referential.switch do
      company.time_zone = nil
      company.save

      line = exported_referential.lines.first
      stop_areas = stop_area_referential.stop_areas.order(Arel.sql('random()')).limit(2)
      route = FactoryBot.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
      journey_pattern = FactoryBot.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
      vehicle_journey = FactoryBot.create :vehicle_journey, journey_pattern: journey_pattern, company: company

      gtfs_export.export_scope = Export::Scope::All.new(exported_referential)

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
      expect(agency.timezone).to eq("Etc/UTC")

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
    exported_referential.switch do
      company.time_zone = "Europe/Paris"
      company.save

      line = exported_referential.lines.first
      stop_areas = stop_area_referential.stop_areas.order(Arel.sql('random()')).limit(2)
      stop_areas.update_all time_zone: "Europe/Paris"

      route = FactoryBot.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
      journey_pattern = FactoryBot.create :journey_pattern, route: route, stop_points: route.stop_points.sample(2)
      vehicle_journey = FactoryBot.create :vehicle_journey, journey_pattern: journey_pattern, company: company
      vehicle_journey.time_tables << (FactoryBot.create :time_table)

      gtfs_export.duration = nil
      gtfs_export.export_scope = Export::Scope::All.new(exported_referential)

      tmp_dir = Dir.mktmpdir

      gtfs_export.export_to_dir tmp_dir

      # The processed export files are re-imported through the GTFS gem
      stop_times_zip_path = File.join(tmp_dir, "#{gtfs_export.zip_file_name}.zip")
      source = GTFS::Source.build stop_times_zip_path, strict: false

      vehicle_journey_at_stops = vehicle_journey.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }
      periods = vehicle_journey.time_tables.inject(0) { |sum, tt| sum + tt.periods.length }
      expect(source.stop_times.count).to eq(vehicle_journey_at_stops.length * periods)

      vehicle_journey_at_stops.each do |vj|
        stop_time = source.stop_times.detect{|s| s.arrival_time == GTFSTime.format_datetime(vj.arrival_time, vj.arrival_day_offset, 'Europe/Paris') }
        expect(stop_time).not_to be_nil, "Did not find stop with time #{GTFSTime.format_datetime(vj.arrival_time, vj.arrival_day_offset, 'Europe/Paris') } among #{source.stop_times.map(&:arrival_time)}"
        expect(stop_time.departure_time).to eq(GTFSTime.format_datetime(vj.departure_time, vj.departure_day_offset, 'Europe/Paris'))
      end
    end
  end

  context 'with journeys' do
    include_context 'with exportable journeys'

    # Too random to be maintained
    it "should correctly export data as valid GTFS output", skip: true do
      # Create context for the tests
      selected_vehicle_journeys = []
      selected_stop_areas_hash = {}
      date_range = nil

      exported_referential.switch do
        date_range = gtfs_export.date_range
        selected_vehicle_journeys = Chouette::VehicleJourney.with_matching_timetable date_range
        gtfs_export.export_scope = Export::Scope::DateRange.new(exported_referential, date_range)
      end

      tmp_dir = Dir.mktmpdir

      ################################
      # Test agencies.txt export
      ################################

      agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')

      exported_referential.switch do
        GTFS::Target.open(agencies_zip_path) do |target|
          gtfs_export.export_companies_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build agencies_zip_path, strict: false
        expect(source.agencies.length).to eq(1)
        agency = source.agencies.first
        expect(agency.id).to eq(company.registration_number)
        expect(agency.name).to eq(company.name)
        expect(agency.lang).to eq(company.default_language)
      end

      ################################
      # Test stops.txt export
      ################################

      stops_zip_path = File.join(tmp_dir, '/test_stops.zip')

      # Fetch the expected exported stop_areas
      exported_referential.switch do
        selected_vehicle_journeys.each do |vehicle_journey|
          vehicle_journey.route.stop_points.each do |stop_point|
            candidates = [stop_point.stop_area]
            if stop_point.stop_area.area_type == "zdep" && stop_point.stop_area.parent
              candidates << stop_point.stop_area.parent
            end
            candidates.each do |stop_area|
              selected_stop_areas_hash[stop_area.id] ||= stop_area if stop_area.commercial?
            end
          end
        end
        selected_stop_areas = selected_stop_areas_hash.values

        GTFS::Target.open(stops_zip_path) do |target|
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
        expect(random_gtfs_stop.location_type).to eq(random_stop_area.area_type == 'zdep' ? '0' : '1')
        # Checks if the parents are similar
        expect(random_gtfs_stop.parent_station).to eq(((random_stop_area.parent.registration_number.presence || random_stop_area.parent.object_id) if random_stop_area.parent))
      end

      ################################
      # Test transfers.txt export
      ################################

      create :connection_link, stop_area_referential: exported_referential.stop_area_referential

      exported_referential.switch do
        transfers_zip_path = File.join(tmp_dir, '/test_transfers.zip')

        stop_area_ids = selected_vehicle_journeys.flat_map(&:stop_points).map(&:stop_area).select(&:commercial?).uniq.map(&:id)
        selected_connections = stop_area_referential.connection_links.where(departure_id: stop_area_ids, arrival_id: stop_area_ids)
        connections = selected_connections.map do |connection|
            [
              connection.departure.registration_number,
              connection.arrival.registration_number
            ].sort
        end.uniq.map do |from, to|
          { from: from, to: to, transfer_type: '2' }
        end

        create :connection_link,
          stop_area_referential: stop_area_referential,
          departure: selected_connections.last.arrival,
          arrival: selected_connections.last.departure

        GTFS::Target.open(transfers_zip_path) do |target|
          gtfs_export.export_transfers_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build transfers_zip_path, strict: false

        expect(source.transfers.length).to eq connections.count
        expect(source.transfers.map do |transfer|
          {
            from: transfer.from_stop_id,
            to: transfer.to_stop_id,
            transfer_type: transfer.type
          }
        end).to match_array connections
      end

      ################################
      # Test lines.txt export
      ################################

      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      exported_referential.switch do
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
        line = exported_referential.lines.first

        expect(route.id).to eq(line.registration_number)
        expect(route.agency_id).to eq(line.company.registration_number)
        expect(route.long_name).to eq(line.published_name)
        expect(route.short_name).to eq(line.number)
        expect(route.type).to eq('3')
        expect(route.desc).to eq(line.comment)
        expect(route.url).to eq(line.url)
      end

      ####################################################
      # Test calendars.txt and calendar_dates.txt export #
      ####################################################

      exported_referential.switch do
        ################################
        # Test trips.txt export
        ################################

        targets_zip_path = File.join(tmp_dir, '/test_trips.zip')

        GTFS::Target.open(targets_zip_path) do |target|
          gtfs_export.export_vehicle_journeys_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build targets_zip_path, strict: false

        # Get VJ merged periods
        periods = []
        selected_vehicle_journeys.each do |vehicle_journey|
          vehicle_journey.time_tables.each do |tt|
            tt.periods.each do |period|
              periods << period if period.range & date_range
            end
          end
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

          e.monday == (random_period.time_table.monday ? "1" : "0")
          e.tuesday == (random_period.time_table.tuesday ? "1" : "0")
          e.wednesday == (random_period.time_table.wednesday ? "1" : "0")
          e.thursday == (random_period.time_table.thursday ? "1" : "0")
          e.friday == (random_period.time_table.friday ? "1" : "0")
          e.saturday == (random_period.time_table.saturday ? "1" : "0")
          e.sunday == (random_period.time_table.sunday ? "1" : "0")
        end

        expect(random_gtfs_calendar).not_to be_nil
        expect((random_period.period_start..random_period.period_end).overlaps?(date_range.begin..date_range.end)).to be_truthy

        # Get VJ merged periods
        vj_periods = []
        # selected_vehicle_journeys.each do |vehicle_journey|
        #   vehicle_journey.flattened_circulation_periods.select{|period| period.range & date_range}.each do |period|
        #     vj_periods << [period,vehicle_journey]
        #   end
        # end
        selected_vehicle_journeys.each do |vehicle_journey|
          vehicle_journey.time_tables.each do |tt|
            tt.periods.each do |period|
              periods << period if period.range & date_range
              vj_periods << [period,vehicle_journey] if period.range & date_range
            end
          end
        end

        # Same size
        expect(source.trips.count).to eq(vj_periods.length)

        # Randomly pick a vehicule_journey / period couple and find the correspondant trip exported in GTFS
        random_vj_period = vj_periods.sample

        # Find matching random stop in exported trips.txt file
        random_gtfs_trip = source.trips.detect {|t|
          (t.service_id == random_vj_period.first.id || t.service_id == random_vj_period.first.time_table.objectid) &&
          t.route_id == random_vj_period.last.route.line.registration_number.to_s &&
          t.short_name == random_vj_period.last.published_journey_name
        }
        expect(random_gtfs_trip).not_to be_nil

        ################################
        # Test stop_times.txt export
        ################################

        stop_times_zip_path = File.join(tmp_dir, '/stop_times.zip')
        GTFS::Target.open(stop_times_zip_path) do |target|
          gtfs_export.export_vehicle_journey_at_stops_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build stop_times_zip_path, strict: false

        expected_stop_times_length = vj_periods.map{|vj| vj.last.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }}.flatten.length

        # Same size
        expect(source.stop_times.count).to eq(expected_stop_times_length)

        # Count the number of stop_times generated by a random VJ and period couple (sop_times depends on a vj, a period and a stop_area)
        vehicle_journey_at_stops = random_vj_period.last.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }

        # Fetch all the stop_times entries exported in GTFS related to the trip (matching the previous VJ / period couple)
        stop_times = source.stop_times.select{|stop_time| stop_time.trip_id == random_gtfs_trip.id }

        # Same size 2
        expect(stop_times.length).to eq(vehicle_journey_at_stops.length)

        # A random stop_time is picked
        random_vehicle_journey_at_stop = vehicle_journey_at_stops.sample
        stop_time = stop_times.detect{|stop_time| stop_time.arrival_time == GTFSTime.format_datetime(random_vehicle_journey_at_stop.arrival_time, random_vehicle_journey_at_stop.arrival_day_offset) }
        expect(stop_time).not_to be_nil
        expect(stop_time.departure_time).to eq(GTFSTime.format_datetime(random_vehicle_journey_at_stop.departure_time, random_vehicle_journey_at_stop.departure_day_offset))
      end
    end
  end
end
