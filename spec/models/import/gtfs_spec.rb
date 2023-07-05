# frozen_string_literal: true

RSpec.describe Import::Gtfs do
  let(:workbench) do
    create :workbench do |workbench|
      workbench.line_referential.update objectid_format: "netex"
      workbench.stop_area_referential.update objectid_format: "netex"
    end
  end

  def create_import(file)
    i = build_import(file)
    i.save!
    i
  end

  def build_import(file)
    Import::Gtfs.new workbench: workbench, local_file: open_fixture(file), creator: "test", name: "test"
  end

  context "when the file is not directly accessible" do
    let(:import) {
      Import::Gtfs.create workbench: workbench, name: "test", creator: "Albator", file: open_fixture('google-sample-feed.zip')
    }

    before(:each) do
      allow(import).to receive(:file).and_return(nil)
    end

    it "should still be able to update the import" do
      import.update status: :failed
      expect(import.reload.status).to eq "failed"
    end
  end

  describe '#force_failure!' do
    let(:import) { create_import 'google-sample-feed.zip' }

     it 'should fail the parent import and the referential' do
        parent = create(:workbench_import)
        resoure = create(:import_resource, import: parent, referential: create(:referential))
        import.update parent: parent
        parent.reload

        import.prepare_referential

        expect(parent).to receive(:force_failure!).and_call_original
        expect(parent).to receive(:do_force_failure!).and_call_original

        import.force_failure!
        expect(import.referential.reload.state).to eq :failed
        expect(import.reload.status).to eq 'failed'
        expect(parent.reload.status).to eq 'failed'
        expect(resoure.reload.referential.state).to eq :failed
     end
  end

  describe "created referential" do
    let(:import) { build_import 'google-sample-feed.zip' }

    it "is named with the import name" do
      import.name = "Import Name"
      import.prepare_referential
      expect(import.referential.name).to eq(import.name)
    end
  end

  describe "#import_agencies" do
    let(:import) { create_import 'google-sample-feed-agency-phone.zip' }
    it "should create a company for each agency" do
      import.import_agencies
      expect(workbench.line_referential.companies.pluck(:registration_number, :name, :default_contact_url, :default_contact_phone, :default_language, :time_zone)).to eq([["DTA","Demo Transit Authority","http://google.com","+33 1 23 45 67 89","en","America/Los_Angeles"]])
    end

    it "should create a resource" do
      expect { import.import_agencies }.to change { import.resources.count }.by 1
      resource = import.resources.last
      expect(resource.name).to eq 'agencies'
      expect(resource.metrics['ok_count'].to_i).to eq 1
      expect(resource.metrics['warning_count'].to_i).to eq 0
      expect(resource.metrics['error_count'].to_i).to eq 0
    end

    context 'when a record lacks its name' do
      before(:each) do
        allow(import.source).to receive(:agencies) {
          [
            GTFS::Agency.new(
              id: 'DTA',
              name: '',
              url: 'http://google.com',
              timezone: 'America/Los_Angeles'
            ),
            GTFS::Agency.new(
              id: 'DTA 2',
              name: 'name',
              url: 'http://google.com',
              timezone: 'America/Los_Angeles'
            )
          ]
        }
      end
      it 'should create a message and continue' do
        companies_count = Chouette::Company.count
        expect do
          import.import_agencies
        end.to change { Import::Message.count }.by 1
        expect(Chouette::Company.count).to eq companies_count + 1
        resource = import.resources.last
        expect(resource.name).to eq 'agencies'
        expect(resource.metrics['ok_count'].to_i).to eq 1
        expect(resource.metrics['warning_count'].to_i).to eq 0
        expect(resource.metrics['error_count'].to_i).to eq 1
      end
    end

    context 'when a default agency is defined' do
      before(:each) do
        allow(import.source).to receive(:agencies) {
          [
            GTFS::Agency.new(
              name: 'Default Agency',
              url: 'http://google.com',
              timezone: 'America/Los_Angeles'
            )
          ]
        }
      end

      it 'should create a company' do
        expect do
          import.import_agencies
        end.to change { Chouette::Company.count }.by 1
      end

      let(:company) { Chouette::Company.last }

      it 'create a company with a default code/registration_number' do
        import.import_agencies
        expect(company).to have_attributes(registration_number: 'default-agency')
      end

      it 'should create a default timezone' do
        import.import_agencies
        expect(import.default_time_zone).to eq(ActiveSupport::TimeZone['America/Los_Angeles'])
      end
    end
  end

  describe "Agencies" do

    let(:agency) { GTFS::Agency.new }

    describe "Decorator" do

      let(:decorator) { Import::Gtfs::Agencies::Decorator.new agency }

      describe "#code" do
        subject { decorator.code }

        context "when GTFS agency id is defined" do
          it { is_expected.to eq(agency.id) }
        end

        context "when GTFS agency id is not defined" do
          before { allow(decorator).to receive(:default_code).and_return("default-id")  }
          it { is_expected.to eq(decorator.default_code) }
        end
      end

      describe "#default_code" do
        subject { decorator.default_code }

        context "when name is 'Agency Name with &é'_ letters'" do
          before { agency.name = "Agency Name with &é'_ letters" }
          it { is_expected.to eq("agency-name-with-e-_-letters") }
        end

        context "when name is blank" do
          before { agency.name = "" }
          it { is_expected.to be_nil }
        end

      end

      describe "#time_zone" do
        subject { decorator.time_zone }

        it "is the TimeZone associated to the agency timezone name" do
          agency.timezone = "Etc/UTC"
          is_expected.to eq(ActiveSupport::TimeZone["Etc/UTC"])
        end

        context "when the agency timezone is invalid" do
          before { agency.timezone = "dummy" }
          it { is_expected.to be_nil }
        end

        context "when the agency timezone is blank" do
          before { agency.timezone = "" }
          it { is_expected.to be_nil }
        end

      end

      describe "#time_zone_name" do
        subject { decorator.time_zone_name }

        it "uses the TimeZone tzinfo name" do
          allow(decorator).to receive(:time_zone).and_return(ActiveSupport::TimeZone["Etc/UTC"])
          is_expected.to eq("Etc/UTC")
        end
      end

      describe "#company_attributes" do
        subject { decorator.company_attributes }

        it "uses the agency name" do
          agency.name = "agency name"
          is_expected.to include(name: agency.name)
        end

        it "uses the agency lang as default language" do
          agency.lang = "agency lang"
          is_expected.to include(default_language: agency.lang)
        end

        it "uses the agency url as default contact url" do
          agency.url = "agency url"
          is_expected.to include(default_contact_url: agency.url)
        end

        it "uses the agency phone as default contact phone" do
          agency.phone = "agency phone"
          is_expected.to include(default_contact_phone: agency.phone)
        end

        it "uses the tine zone name" do
          agency.timezone = "Etc/UTC"
          is_expected.to include(time_zone: agency.timezone)
        end

        it "uses the fare url" do
          agency.fare_url = 'test.enroute.mobi'
          is_expected.to include(fare_url: 'test.enroute.mobi')
        end
      end

      describe "validation" do
        subject { decorator.valid? }

        context "when the agency has a defined id and a valid time_zone" do
          before do
            agency.id = "defined"
            agency.timezone = "Europe/Paris"
            decorator.mandatory_id = true
            decorator.default_time_zone = ActiveSupport::TimeZone["Europe/Paris"]
          end

          it { is_expected.to be_truthy }
        end

        describe "missing agency id" do
          context "when agency id is mandatory and agency id is blank" do
            before do
              agency.id = ""
              decorator.mandatory_id = true
            end

            it "creates an error 'gtfs.agencies.missing_agency_id'" do
              is_expected.to be_falsy
              expect(decorator.errors).to include({ criticity: :error, message_key: 'gtfs.agencies.missing_agency_id' })
            end
          end

        end

        describe "invalid time zone" do
          context "when agency timezone doesn't match a known TimeZone" do
            before do
              agency.timezone = "invalid timezone"
            end

            it "creates an error 'invalid_time_zone' with invalid timezone name" do
              is_expected.to be_falsy
              expect(decorator.errors).to include({ criticity: :error, message_key: :invalid_time_zone, message_attributes: { time_zone: agency.timezone }})
            end
          end
        end

        describe "default time zone" do
          context "when the default time zone is known and the agency doesn't match it" do
            before do
              decorator.default_time_zone = ActiveSupport::TimeZone["Etc/UTC"]
              agency.timezone = "Europe/Paris"
            end

            it "creates an error 'gtfs.agencies.default_time_zone'" do
              is_expected.to be_falsy
              expect(decorator.errors).to include({ criticity: :error, message_key: 'gtfs.agencies.default_time_zone'})
            end
          end
        end
      end

    end

  end

  describe "Attributions" do

    let!(:attribution1) do
      GTFS::Attribution.new.tap do |attribution|
        attribution.trip_id = "AB1"
        attribution.operator = true
        attribution.organization_name = "Company1"
      end
    end

    let!(:attribution2) do
      GTFS::Attribution.new.tap do |attribution|
        attribution.trip_id = "AB2"
        attribution.operator = false
        attribution.organization_name = "Company2"
      end
    end

    it { expect(attribution1.operator?).to be_truthy }
    it { expect(attribution2.operator?).not_to be_truthy }
  end

  describe "#import_attributions" do
    let(:import) { create_import 'google-sample-feed-with-attributions.zip' }
    let(:referential) { import.referential }
    let(:vehicle_journey) { referential.vehicle_journeys.by_code(import.code_space, 'AB1').first }
    let(:company_name) { 'Demo Transit Authority' }

    context "when there is only one company with the name 'Demo Transit Authority'" do
      before { import.import_without_status }

      it 'should associate vehicle_journey to company' do
        expect(vehicle_journey.company.name).to eq(company_name)
      end
    end
  end

  describe '#import_stops' do
    let(:import) do
      build_import('google-sample-feed-with-stop-desc.zip').tap do |import|
        import.default_time_zone = ActiveSupport::TimeZone['America/Los_Angeles']
      end
    end
    it "should create a stop_area for each stop" do
      import.import_stops

      defined_attributes = [
        :registration_number, :name, :parent_id, :latitude, :longitude, :comment, :public_code, :mobility_impaired_accessibility
      ]
      expected_attributes = [
        ["AMV", "Amargosa Valley (Demo)", nil, 36.641496, -116.40094,'amv', nil,'unknown'],
        ["EMSI", "E Main St / S Irving St (Demo)", nil, 36.905697, -116.76218,'emsi', nil,'unknown'],
        ["DADAN", "Doing Ave / D Ave N (Demo)", nil, 36.909489, -116.768242,'dadan', nil,'unknown'],
        ["NANAA", "North Ave / N A Ave (Demo)", nil, 36.914944, -116.761472,'nanaa', nil,'unknown'],
        ["NADAV", "North Ave / D Ave N (Demo)", nil, 36.914893, -116.76821,'nadav', nil,'unknown'],
        ["STAGECOACH", "Stagecoach Hotel & Casino (Demo)", nil, 36.915682, -116.751677,'stagecoach', nil,'unknown'],
        ["BULLFROG", "Bullfrog (Demo)", nil, 36.88108, -116.81797,'bullfrog', nil, 'yes'],
        ["BEATTY_AIRPORT", "Nye County Airport (Demo)", nil, 36.868446, -116.784582,'beatty_airport', 'Test','unknown'],
        ["FUR_CREEK_RES", "Furnace Creek Resort (Demo)", nil, 36.425288, -117.133162,'fur_creek_res', '1','unknown'],
      ]

      expect(workbench.stop_area_referential.stop_areas.pluck(*defined_attributes)).to match_array(expected_attributes)
    end

    it "should use the agency timezone by default" do
      import.import_agencies
      import.import_stops

      expect(workbench.stop_area_referential.stop_areas.first.time_zone).to eq("America/Los_Angeles")
    end

    context 'with an invalid timezone' do
      let(:stop) do
        GTFS::Stop.new(
          id: 'stop_id',
          name: 'stop',
          location_type: '2',
          timezone: "incorrect timezone"
        )
      end

      before(:each) do
        allow(import.source).to receive(:stops) { [stop] }
      end

      it 'should create an error message' do
        expect { import.import_stops }.to change { Import::Message.count }.by(1)
          .and(change { Chouette::StopArea.count })
      end
    end

    context 'with an inexistant parent stop' do
      let(:child) do
        GTFS::Stop.new(
          id: 'child_id',
          name: 'child',
          parent_station: 'parent_id',
          location_type: '2'
        )
      end

      before(:each) do
        allow(import.source).to receive(:stops) { [child] }
      end

      it 'should create an error message if the parent is inexistant' do
        expect { import.import_stops }.to change { Import::Message.count }.by(1)
          .and(change { Chouette::StopArea.count })
      end
    end

    context 'with parent defined after child' do
      let(:child_gtfs_stop) do
        GTFS::Stop.new(
          id: 'child_id',
          name: 'child',
          parent_station: 'parent_id',
          location_type: '2'
        )
      end

      let(:parent_gtfs_stop) do
        GTFS::Stop.new(
          id: 'parent_id',
          name: 'Parent',
          parent_station: '',
          location_type: '1'
        )
      end

      before(:each) do
        allow(import.source).to receive(:stops) { [child_gtfs_stop, parent_gtfs_stop] }
      end

      let(:child_stop_area) do
        Chouette::StopArea.find_by!(registration_number: child_gtfs_stop.id)
      end

      let(:parent_stop_area) do
        Chouette::StopArea.find_by!(registration_number: parent_gtfs_stop.id)
      end

      it 'should create an error message if the parent is inexistant' do
        expect { import.import_stops }.to change { Import::Message.count }.by(0)
                                            .and(change { Chouette::StopArea.count }.by(2))
        expect(child_stop_area.parent).to eq(parent_stop_area)
      end
    end

    context 'with a parent stop' do
      let(:parent) do
        GTFS::Stop.new(
          id: 'parent_id',
          name: 'parent',
          location_type: '1',
          timezone: 'America/Los_Angeles'
        )
      end

      let(:child) do
        GTFS::Stop.new(
          id: 'child_id',
          name: 'child',
          parent_station: 'parent_id'
        )
      end

      before(:each) do
        allow(import.source).to receive(:stops) { [parent, child] }
      end

      it 'should link the stop_areas' do
        import.import_stops
        parent = Chouette::StopArea.find_by(registration_number: 'parent_id')
        child = Chouette::StopArea.find_by(registration_number: 'child_id')
        expect(child.parent).to eq parent
      end

      it 'should use the parent timezone' do
        import.import_stops
        child = Chouette::StopArea.find_by(registration_number: 'child_id')
        expect(child.time_zone).to eq 'America/Los_Angeles'
      end

      context 'when the parent is not valid' do
        let(:parent) do
          GTFS::Stop.new(
            id: 'parent_id',
            name: '',
            location_type: '1'
          )
        end

        it "should create the child and raise an error message" do
          expect { import.import_stops }.to change { Import::Message.count }.by(2)
            .and(change { Chouette::StopArea.count })
        end
      end
    end
  end

  describe '#import_transfers' do
    let(:import) { build_import 'google-sample-feed.zip' }
    it 'should create a ConnectionLink for each type 2 transfer' do
      import.prepare_referential
      expect { import.import_transfers }.to change { Chouette::ConnectionLink.count }.by 1
      link = Chouette::ConnectionLink.last
      expect(link.departure.registration_number).to eq 'BEATTY_AIRPORT'
      expect(link.arrival.registration_number).to eq 'FUR_CREEK_RES'
      expect(link.both_ways).to be_truthy
      expect(link.default_duration).to eq 6000
    end

    context 'with an existing connection' do
      before do
        import.prepare_referential
        from = import.referential.stop_area_referential.stop_areas.find_by registration_number: 'BEATTY_AIRPORT'
        to = import.referential.stop_area_referential.stop_areas.find_by registration_number: 'FUR_CREEK_RES'
        import.stop_area_provider.connection_links.create!(departure: from, arrival: to, both_ways: true, default_duration: 12)
      end

      it 'should not create a duplicate ConnectionLink' do
        import.prepare_referential
        expect { import.import_transfers }.to_not change { Chouette::ConnectionLink.count }
      end
    end

    context 'whith from_stop_id same as to_stop_id' do
      let(:import) { build_import 'google-sample-feed-with-incorrect-transfer.zip' }

      it 'should create a warning if a tranfer have the same from stop and to stop' do
        import.prepare_referential
        expect { import.import_transfers }.to change { Import::Message.count }.by(1)
      end
    end
  end


  describe '#import_routes' do
    let(:import) { build_import 'google-sample-feed-with-color.zip' }
    it 'should create a line for each route' do
      import.import_routes

      defined_attributes = [
        :registration_number, :name, :number, :published_name,
        "companies.registration_number", :comment, :url,
        :transport_mode, :color, :text_color
      ]
      expected_attributes = [
        ["AAMV", "Airport - Amargosa Valley", "50", "Airport - Amargosa Valley", nil, nil, nil, "bus", nil, nil],
        ["CITY", "City", "40", "City", nil, nil, nil, "bus", nil, nil],
        ["STBA", "Stagecoach - Airport Shuttle", "30", "Stagecoach - Airport Shuttle", nil, nil, nil, "bus",nil,nil],
        ["BFC", "Bullfrog - Furnace Creek Resort", "20", "Bullfrog - Furnace Creek Resort", nil, nil, nil, "bus","000000","ABCDEF"],
        ["AB", "Airport - Bullfrog", "10", "Airport - Bullfrog", nil, nil, nil, "bus","ABCDEF","012345"]
      ]

      expect(workbench.line_referential.lines.includes(:company).pluck(*defined_attributes)).to match_array(expected_attributes)
    end

    context "with a company" do
      let(:agency_name){ 'name' }
      let(:agency){
        GTFS::Agency.new(
          id: 'agency_id',
          name: agency_name,
          url: 'http://google.com',
          timezone: 'America/Los_Angeles'
        )
      }
      let(:route){
        GTFS::Route.new(
          id: 'route_id',
          short_name: 'route',
          agency_id: 'agency_id'
        )
      }
      before(:each) do
        allow(import.source).to receive(:agencies) { [agency] }
        allow(import.source).to receive(:routes) { [route] }
        import.import_agencies
      end

      it 'should link the line' do
        import.import_routes
        parent = Chouette::Company.find_by(registration_number: agency.id)
        child = Chouette::Line.find_by(registration_number: route.id)
        expect(child.company).to eq parent
      end

      context "when the agency is not valid" do
        let(:agency_name){ nil }

        it "shoud not create the line" do
          expect { import.import_routes }.to_not(change { Chouette::Line.count })
        end
      end
    end
  end

  describe "time_of_day" do
    context "with a UTC+1 Agency"do
      let(:import) { build_import 'time_of_day_feed_1.zip' }

      it "should have correct time of day values" do
        import.prepare_referential
        import.import_services
        import.import_stop_times

        expected_attributes = [
          ['S1','23:00:00 day:-1'],
          ['S2','23:00:05 day:-1']
        ]

        a = []
        referential.vehicle_journey_at_stops.each do |vjas|
          a << [
            vjas.stop_point.registration_number,
            vjas.departure_time_of_day.to_s
          ]
        end
        expect(a).to match_array(expected_attributes)
      end
    end

    context "with a UTC-8 Agency"do
      let(:import) { build_import 'time_of_day_feed_8.zip' }

      it "should have correct time of day values" do
        import.prepare_referential
        import.import_services
        import.import_stop_times

        expected_attributes = [
          ['S1','00:00:00 day:1'],
          ['S2','00:00:05 day:1']
        ]

        a = []
        referential.vehicle_journey_at_stops.each do |vjas|
          a << [
            vjas.stop_point.registration_number,
            vjas.departure_time_of_day.to_s
          ]
        end
        expect(a).to match_array(expected_attributes)
      end
    end
  end

  describe "#import_stop_times" do
    let(:import) { build_import 'google-sample-feed.zip' }

    before do
      import.prepare_referential
      import.import_services
      allow_any_instance_of(Chouette::Route).to receive(:has_tomtom_features?){ true }
    end

    it "should calculate costs" do
      calculated = []
      allow_any_instance_of(Chouette::Route).to receive(:calculate_costs!) { |route|
        calculated << route
      }

      import.import_stop_times
      import.referential.vehicle_journeys.map(&:route).uniq.each do |route|
        expect(calculated).to include(route)
      end
    end

    it "should create a Route for each trip" do
      import.import_stop_times
      defined_attributes = [
        "lines.registration_number", :wayback, :name
      ]
      expected_attributes = [
        ["AB", "outbound", "to Bullfrog"],
        ["AB", "inbound", "to Airport"],
        ["CITY", "inbound", "Inbound"],
        ["BFC", "outbound", "to Furnace Creek Resort"],
        ["BFC", "inbound", "to Bullfrog"],
        ["AAMV", "outbound", "to Amargosa Valley"],
        ["AAMV", "inbound", "to Airport"],
      ]
      expect(import.referential.routes.includes(:line).pluck(*defined_attributes)).to match_array(expected_attributes)
    end

    it "should create a JourneyPattern for each trip" do
      import.import_stop_times
      defined_attributes = [
        :name, :published_name
      ]
      expected_attributes = [
        ["to Bullfrog", "to Bullfrog"],
        ["to Airport", "to Airport"],
        ["Inbound", nil],
        ["to Furnace Creek Resort", "to Furnace Creek Resort"],
        ["to Bullfrog", "to Bullfrog"],
        ["to Amargosa Valley", "to Amargosa Valley"],
        ["to Airport", "to Airport"],
      ]
      expect(import.referential.journey_patterns.pluck(*defined_attributes)).to match_array(expected_attributes)
    end

    it "should create a VehicleJourney for each trip" do
      import.import_stop_times
      defined_attributes = ->(v) {
        [v.published_journey_name, v.time_tables.first&.comment]
      }
      expected_attributes = [
        ["CITY2", "FULLW"],
        ["AB1", "FULLW"],
        ["AB2", "FULLW"],
        ["BFC1", "FULLW"],
        ["BFC2", "FULLW"],
        ["AAMV1", "WE"],
        ["AAMV2", "WE"],
        ["AAMV3", "WE"],
        ["AAMV4", "WE"]
      ]
      expect(import.referential.vehicle_journeys.map(&defined_attributes)).to match_array(expected_attributes)
    end

    it "should create a VehicleJourneyAtStop for each stop_time" do
      import.import_stop_times

      def t(value)
        Time.parse(value)
      end

      expected_attributes = [
        ['EMSI', 0, t('2000-01-01 14:30:00 UTC'), t('2000-01-01 14:30:00 UTC'), 0, 0],
        ['DADAN', 1, t('2000-01-01 14:37:00 UTC'), t('2000-01-01 14:35:00 UTC'), 0, 0],
        ['NADAV', 2, t('2000-01-01 14:44:00 UTC'), t('2000-01-01 14:42:00 UTC'), 0, 0],
        ['NANAA', 3, t('2000-01-01 14:51:00 UTC'), t('2000-01-01 14:49:00 UTC'), 0, 0],
        ['STAGECOACH', 4, t('2000-01-01 14:58:00 UTC'), t('2000-01-01 14:56:00 UTC'), 0, 0],
        ['BEATTY_AIRPORT', 0, t('2000-01-01 23:00:00 UTC'), t('2000-01-01 23:00:00 UTC'), 0, 0],
        ['BULLFROG', 1, t('2000-01-01 00:05:00 UTC'), t('2000-01-01 00:00:00 UTC'), 1, 1],
        ['BULLFROG', 0, t('2000-01-01 20:05:00 UTC'), t('2000-01-01 20:05:00 UTC'), 0, 0],
        ['BEATTY_AIRPORT', 1, t('2000-01-01 20:15:00 UTC'), t('2000-01-01 20:15:00 UTC'), 0, 0],
        ['BULLFROG', 0, t('2000-01-01 16:20:00 UTC'), t('2000-01-01 16:20:00 UTC'), 0, 0],
        ['FUR_CREEK_RES', 1, t('2000-01-01 17:20:00 UTC'), t('2000-01-01 17:20:00 UTC'), 0, 0],
        ['FUR_CREEK_RES', 0, t('2000-01-01 19:00:00 UTC'), t('2000-01-01 19:00:00 UTC'), 0, 0],
        ['BULLFROG', 1, t('2000-01-01 20:00:00 UTC'), t('2000-01-01 20:00:00 UTC'), 0, 0],
        ['BEATTY_AIRPORT', 0, t('2000-01-01 16:00:00 UTC'), t('2000-01-01 16:00:00 UTC'), 0, 0],
        ['AMV', 1, t('2000-01-01 17:00:00 UTC'), t('2000-01-01 17:00:00 UTC'), 0, 0],
        ['BEATTY_AIRPORT', 0, t('2000-01-01 21:00:00 UTC'), t('2000-01-01 21:00:00 UTC'), 0, 0],
        ['AMV', 1, t('2000-01-01 22:00:00 UTC'), t('2000-01-01 22:00:00 UTC'), 1, 1],
        ['AMV', 0, t('2000-01-01 07:30:00 UTC'), t('2000-01-01 07:30:00 UTC'), 1, 1],
        ['BEATTY_AIRPORT', 1, t('2000-01-01 09:00:00 UTC'), t('2000-01-01 09:00:00 UTC'), 1, 1],
        ['AMV', 0, t('2000-01-01 18:00:00 UTC'), t('2000-01-01 18:00:00 UTC'), 0, 0],
        ['BEATTY_AIRPORT', 1, t('2000-01-01 19:00:00 UTC'), t('2000-01-01 19:00:00 UTC'), 0, 0]
      ]

      a = []
      referential.vehicle_journey_at_stops.each do |vjas|
        a << [
          vjas.stop_point.registration_number,
          vjas.stop_point.position,
          vjas.departure_time_of_day.to_vehicle_journey_at_stop_time,
          vjas.arrival_time_of_day.to_vehicle_journey_at_stop_time,
          vjas.departure_time_of_day.day_offset,
          vjas.arrival_time_of_day.day_offset
        ]
      end
      expect(a).to match_array(expected_attributes)
    end

    context 'with multiple trips with non zero first day offet' do
      let(:import) { build_import 'day-offset-sample-feed.zip' }

      it 'should reuse the calendars' do
        import.import_stop_times

        expect(referential.time_tables.count).to eq 2
      end
    end

    context 'with invalid stop times' do
      let(:import) { build_import 'invalid_stop_times.zip' }
      it "should create no VehicleJourney" do
        expect{ import.import_stop_times }.to_not change { Chouette::VehicleJourney.count }
      end
    end
  end

  describe "#import" do
    context "when there is an issue with the source file" do
      let(:import) { build_import 'google-sample-feed.zip' }
      it "should fail" do
        allow(import.source).to receive(:agencies){ raise GTFS::InvalidSourceException }
        expect { import.import }.to_not raise_error
        expect(import.status).to eq :failed
      end
    end
  end

  describe "#referential_metadata" do
    context 'without calendar_dates.xml' do
      let(:import) { build_import 'google-sample-feed-no-calendar_dates.zip' }
      it "should not raise an error" do
        expect { import.referential_metadata }.to_not raise_error
      end
    end
  end

  describe '#download_local_file' do
    let(:file) { 'google-sample-feed.zip' }
    let(:import) do
      Import::Gtfs.create! name: 'GTFS test', creator: 'Test', workbench: workbench, file: open_fixture(file), download_host: 'rails_host'
    end

    let(:download_url) { "#{import.download_host}/workbenches/#{import.workbench_id}/imports/#{import.id}/internal_download?token=#{import.token_download}" }

    before do
      stub_request(:get, download_url).to_return(status: 200, body: read_fixture(file))
    end

    it 'should download local_file' do
      expect(File.read(import.download_local_file)).to eq(read_fixture(file))
    end
  end

  describe '#download_uri' do
    let(:import) { Import::Gtfs.new }

    before do
      allow(import).to receive(:download_path).and_return('/download_path')
    end

    context "when download_host is 'front'" do
      before { allow(import).to receive(:download_host).and_return('front') }
      it 'returns http://front/download_path' do
        expect(import.download_uri.to_s).to eq('http://front/download_path')
      end
    end

    context "when download_host is 'front:3000'" do
      before { allow(import).to receive(:download_host).and_return('front:3000') }
      it 'returns http://front:3000/download_path' do
        expect(import.download_uri.to_s).to eq('http://front:3000/download_path')
      end
    end

    context "when download_host is 'http://front:3000'" do
      before { allow(import).to receive(:download_host).and_return('http://front:3000') }
      it 'returns http://front:3000/download_path' do
        expect(import.download_uri.to_s).to eq('http://front:3000/download_path')
      end
    end

    context "when download_host is 'https://front:3000'" do
      before { allow(import).to receive(:download_host).and_return('https://front:3000') }
      it 'returns https://front:3000/download_path' do
        expect(import.download_uri.to_s).to eq('https://front:3000/download_path')
      end
    end

    context "when download_host is 'http://front'" do
      before { allow(import).to receive(:download_host).and_return('http://front') }
      it 'returns http://front/download_path' do
        expect(import.download_uri.to_s).to eq('http://front/download_path')
      end
    end
  end

  describe '#download_host' do
    it 'should return host defined by Rails.application.config.rails_host' do
      allow(Rails.application.config).to receive(:rails_host).and_return('download_host')
      expect(Import::Gtfs.new.download_host).to eq('download_host')
    end
  end

  describe '#download_path' do
    let(:file) { 'google-sample-feed.zip' }
    let(:import) do
      Import::Gtfs.create! name: 'GTFS test', creator: 'Test', workbench: workbench, file: open_fixture(file), download_host: 'rails_host'
    end

    it 'should return the pathwith the token' do
      expect(import.download_path).to eq("/workbenches/#{import.workbench_id}/imports/#{import.id}/internal_download?token=#{import.token_download}")
    end
  end

  describe '#referential_metadata' do
    subject { import.referential_metadata }

    let(:import) { create_import 'google-sample-feed.zip' }

    context 'when Source validity period is 20300101-20301231' do
      before { allow(import.source).to receive(:validity_period).and_return(Period.parse('20300101..20301231')) }

      it { is_expected.to have_attributes(periodes: contain_exactly(import.source.validity_period)) }
    end
  end

  describe Import::Gtfs::Shapes do
    let(:part) { described_class.new import }
    let(:import) { double shape_provider: shape_provider, source: source, code_space: code_space }

    let(:context) do
      Chouette.create do
        code_space
        shape_provider
      end
    end
    let(:shape_provider) { context.shape_provider }
    let(:code_space) { context.code_space }

    let(:source) { double shapes: [] }

    describe '#import!' do
      context "when a GTFS Shape 'test' is provided by the source" do
        let(:line) { Geo::Line.from([[48.858093, 2.294694], [8.858094, 2.294695]]) }
        let(:gtfs_shape) do
          GTFS::Shape.new(id: 'test').tap do |shape|
            line.each do |position|
              shape.points << GTFS::ShapePoint.new(latitude: position.latitude, longitude: position.longitude) 
            end
          end
        end
        before { source.shapes << gtfs_shape }

        context 'when no Shape exists with the same code' do
          it { expect { part.import! }.to change { shape_provider.shapes.count }.by(1) }

          describe 'created Shape' do
            before { part.import! }

            let(:shape) { shape_provider.shapes.last }

            describe 'codes' do
              subject { shape.codes }
              it { is_expected.to include(an_object_having_attributes(code_space: code_space, value: 'test')) }
            end

            describe 'geometry' do 
              subject { Geo::Line.from_rgeos shape.geometry }

              it { is_expected.to be_within(0.0001).of(line) }
            end
          end
        end

        context 'when a Shape exists with the same code' do
          # TODO
        end
      end
    end

    describe Import::Gtfs::Shapes::Decorator do
      let(:gtfs_shape) { GTFS::Shape.new }
      subject(:decorator) { described_class.new gtfs_shape }

      describe '#valid?' do
        subject { decorator.valid? }

        context 'when an error exists before' do
          it { is_expected.to be_truthy }
        end

        context 'when an error is detected' do
          before { allow(decorator).to receive(:points).and_return(double(count: 1_000_000)) }
          it { is_expected.to be_falsy }
        end
      end

      describe '.maximum_point_count' do
        subject { described_class.maximum_point_count }
        it { is_expected.to eq(10_000) }
      end

      describe '#code_value' do
        subject { decorator.code_value }

        context 'when GTFS Shape id is "dummy"' do
          before { gtfs_shape.id = 'dummy' }
          it { is_expected.to eq('dummy') }
        end
      end

      describe '#code' do
        subject { decorator.code }

        describe 'when code_space is undefined' do
          it { is_expected.to be_nil }
        end

        describe 'when code space is defined' do
          let(:code_space) { CodeSpace.new(short_name: 'test') }
          let(:code_value) { 'code_value' }
          before do
            decorator.code_space = code_space
            allow(decorator).to receive(:code_value).and_return(code_value)
          end
          it do
            is_expected.to have_attributes(
              code_space: an_object_having_attributes(short_name: 'test'),
              value: code_value
            )
          end
        end
      end

      describe '#errors' do
        describe 'point count validation' do
          let(:points) { double(count: point_count) }
          before do
            allow(decorator).to receive(:points).and_return(points)
          end

          subject do
            decorator.valid?
            decorator.errors end

          context 'when the GTFS Shape has 10000 points' do
            let(:point_count) { 10_000 }
            it { is_expected.to be_empty }
          end

          context 'when the GTFS Shape has 10001 points' do
            let(:point_count) { 10_001 }
            it { is_expected.to include(a_hash_including(criticity: :error)) }
            it { is_expected.to include(a_hash_including(message_key: :unreasonable_shape)) }

            context 'when GTFS shape_id is 42' do
              before { gtfs_shape.id = 42 }
              it { is_expected.to include(a_hash_including(message_attributes: { shape_id: 42 })) }
            end
          end
        end
      end
    end
  end

  describe Import::Gtfs::FareProducts::Decorator do
    subject(:decorator) { described_class.new(fare_attribute) }

    let(:fare_attribute) { GTFS::FareAttribute.new }

    describe '#company' do
      subject { decorator.company }

      context 'when no agency_id is defined' do
        before { allow(decorator).to receive(:default_company).and_return(double('Default Company')) }
        it { is_expected.to eq(decorator.default_company) }
      end

      context 'when agency_id is defined' do
        before { fare_attribute.agency_id = 'dummy' }

        before do
          decorator.company_scope = company_scope
          allow(company_scope).to receive(:find_by)
            .with(registration_number: decorator.agency_id)
            .and_return(company)
        end
        let(:company_scope) { double }
        let(:company) { double('Company with agency_id as registration_number') }

        it { is_expected.to eq(company) }
      end
    end
  end

  describe Import::Gtfs::Services::Decorator do
    subject(:decorator) { described_class.new(service) }

    let(:service) { GTFS::Service.new }

    describe '#days_of_week' do
      subject { decorator.days_of_week }

      %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
        context "when GTFS Service includes #{day}" do
          before { allow(service).to receive("#{day}?").and_return(true) }

          it { is_expected.to send("be_#{day}") }
        end

        context "when GTFS Service excludes #{day}" do
          before { allow(service).to receive("#{day}?").and_return(false) }

          it { is_expected.to_not send("be_#{day}") }
        end
      end
    end

    describe '#period' do
      subject { decorator.period }

      context 'when GTFS Service date_range is nil' do
        before { allow(service).to receive(:date_range).and_return(nil) }

        it { is_expected.to be_nil }
      end

      context 'when GTFS Service date_range is 2030-01-01..2030-01-31' do
        before { allow(service).to receive(:date_range).and_return(Period.parse('2030-01-01..2030-01-31')) }

        it { is_expected.to eq(Period.parse('2030-01-01..2030-01-31')) }
      end
    end

    describe '#included_dates' do
      subject { decorator.included_dates }

      context 'when no GTFS date is present' do
        before { allow(service).to receive(:calendar_dates).and_return([]) }

        it { is_expected.to be_empty }
      end

      context 'when a GTFS date is added on 2030-01-01' do
        let(:gtfs_date) { GTFS::CalendarDate.new(date: '2030-01-01', exception_type: GTFS::CalendarDate::ADDED) }
        before { allow(service).to receive(:calendar_dates).and_return([gtfs_date]) }

        it { is_expected.to contain_exactly(Date.parse('2030-01-01')) }
      end

      context 'when two GTFS dates are added on 2030-01-01 and 2030-01-31' do
        let(:gtfs_dates) do
          %w[2030-01-01 2030-01-31].map do |value|
            GTFS::CalendarDate.new(date: value, exception_type: GTFS::CalendarDate::ADDED)
          end
        end

        before { allow(service).to receive(:calendar_dates).and_return(gtfs_dates) }

        it { is_expected.to contain_exactly(Date.parse('2030-01-01'), Date.parse('2030-01-31')) }
      end

      context 'when a GTFS date is removed' do
        let(:gtfs_date) { GTFS::CalendarDate.new(exception_type: GTFS::CalendarDate::REMOVED) }
        before { allow(service).to receive(:calendar_dates).and_return([gtfs_date]) }

        it { is_expected.to be_empty }
      end

      context 'when a GTFS date is invalid' do
        let(:gtfs_date) { GTFS::CalendarDate.new(date: 'invalid', exception_type: GTFS::CalendarDate::ADDED) }
        before { allow(service).to receive(:calendar_dates).and_return([gtfs_date]) }

        it { is_expected.to be_empty }
      end
    end

    describe '#excluded_dates' do
      subject { decorator.excluded_dates }

      context 'when no GTFS date is present' do
        before { allow(service).to receive(:calendar_dates).and_return([]) }

        it { is_expected.to be_empty }
      end

      context 'when a GTFS date is removed on 2030-01-01' do
        let(:gtfs_date) { GTFS::CalendarDate.new(date: '2030-01-01', exception_type: GTFS::CalendarDate::REMOVED) }
        before { allow(service).to receive(:calendar_dates).and_return([gtfs_date]) }

        it { is_expected.to contain_exactly(Date.parse('2030-01-01')) }
      end

      context 'when two GTFS dates are removed on 2030-01-01 and 2030-01-31' do
        let(:gtfs_dates) do
          %w[2030-01-01 2030-01-31].map do |value|
            GTFS::CalendarDate.new(date: value, exception_type: GTFS::CalendarDate::REMOVED)
          end
        end

        before { allow(service).to receive(:calendar_dates).and_return(gtfs_dates) }

        it { is_expected.to contain_exactly(Date.parse('2030-01-01'), Date.parse('2030-01-31')) }
      end

      context 'when a GTFS date is added' do
        let(:gtfs_date) { GTFS::CalendarDate.new(exception_type: GTFS::CalendarDate::ADDED) }
        before { allow(service).to receive(:calendar_dates).and_return([gtfs_date]) }

        it { is_expected.to be_empty }
      end

      context 'when a GTFS date is invalid' do
        let(:gtfs_date) { GTFS::CalendarDate.new(date: 'invalid', exception_type: GTFS::CalendarDate::REMOVED) }
        before { allow(service).to receive(:calendar_dates).and_return([gtfs_date]) }

        it { is_expected.to be_empty }
      end
    end

    describe '#memory_timetable' do
      subject(:memory_timetable) { decorator.memory_timetable }

      it 'should be normalized' do
        # Timetable.new.normalize! returns a double which #normalized? => true
        allow(Timetable).to receive_message_chain(:new, :normalize!).and_return(double(normalized?: true))

        is_expected.to be_normalized
      end

      describe '#periods' do
        subject { memory_timetable.periods }

        context 'when Decorator period is not defined' do
          before { allow(decorator).to receive(:period).and_return(nil) }

          it { is_expected.to be_empty }
        end

        context 'when Decorator period is 2030-01-01..2030-01-31' do
          before do
            allow(decorator).to receive(:period).and_return(Period.parse('2030-01-01..2030-01-31'))
            allow(decorator).to receive(:days_of_week).and_return(Timetable::DaysOfWeek.all)
          end

          it { is_expected.to contain_exactly(an_object_having_attributes(date_range: decorator.period)) }
        end

        context 'when Decorator days of week is Monday and Saturday' do
          before do
            allow(decorator).to receive(:period).and_return(Period.parse('2030-01-01..2030-01-31'))
            allow(decorator).to receive(:days_of_week).and_return(Timetable::DaysOfWeek.none.enable(:monday).enable(:saturday))
          end

          it { is_expected.to contain_exactly(an_object_having_attributes(days_of_week: decorator.days_of_week)) }
        end
      end

      describe '#included_dates' do
        subject { memory_timetable.included_dates }

        context 'when Decorator included dates are [2030-01-01, 2030-01-15]' do
          before do
            allow(decorator).to receive(:included_dates).and_return([Date.parse('2030-01-01'),
                                                                     Date.parse('2030-01-15')])
          end

          it { is_expected.to match_array(decorator.included_dates) }
        end
      end

      describe '#excluded_dates' do
        subject { memory_timetable.excluded_dates }

        context 'when Decorator included dates are [2030-01-01, 2030-01-15]' do
          before do
            allow(decorator).to receive(:period).and_return(Period.parse('2030-01-01..2030-01-31'))
            allow(decorator).to receive(:days_of_week).and_return(Timetable::DaysOfWeek.all)

            allow(decorator).to receive(:excluded_dates).and_return([Date.parse('2030-01-01'),
                                                                     Date.parse('2030-01-15')])
          end

          it { is_expected.to match_array(decorator.excluded_dates) }
        end
      end
    end

    describe '#empty' do
      context 'when memory timetable is empty' do
        before { allow(decorator).to receive(:memory_timetable).and_return(double(empty?: true)) }
        it { is_expected.to be_empty }
      end

      context 'when memory timetable is not empty' do
        before { allow(decorator).to receive(:memory_timetable).and_return(double(empty?: false)) }
        it { is_expected.to_not be_empty }
      end
    end

    describe '#time_table' do
      subject { decorator.time_table }

      context 'when service_id is defined' do
        before { allow(decorator).to receive(:service_id).and_return('service_id') }

        it { is_expected.to be_a(Chouette::TimeTable) }

        context 'when Decorator name is "dummy"' do
          before { allow(decorator).to receive(:name).and_return('dummy') }

          it { is_expected.to have_attributes(comment: decorator.name) }
        end

        it 'should apply memory timetable periods and in/excluded_dates' do
          time_table = Chouette::TimeTable.new
          allow(Chouette::TimeTable).to receive(:new).and_return(time_table)

          expect(time_table).to receive(:apply).with(decorator.memory_timetable).and_return(time_table)
          is_expected.to be(time_table)
        end
      end

      context "when service_id isn't defined" do
        it { is_expected.to be_nil }
      end
    end
  end
end
