# frozen_string_literal: true

RSpec.describe Export::Gtfs::VehicleJourneys do
  let(:export_scope) { Export::Scope::All.new context.referential }
  let(:index) { export.index }
  let(:export) do
    Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup
  end

  let(:part) do
    Export::Gtfs::VehicleJourneys.new export
  end

  let(:context) do
    Chouette.create do
      time_table :default
      vehicle_journey time_tables: [:default]
      vehicle_journey time_tables: [:default]
    end
  end

  let(:time_table) { context.time_table(:default) }
  let(:vehicle_journeys) { context.vehicle_journeys }

  before do
    context.referential.switch
    index.register_services time_table, [Export::Gtfs::Service.new(time_table.objectid)]
  end

  it 'registers the GTFS Trip identifiers used for each VehicleJourney' do
    part.perform
    vehicle_journeys.each do |vehicle_journey|
      expect(index.trip_ids(vehicle_journey.id)).to eq([vehicle_journey.objectid])
    end
  end

  context 'when the Line has flexible service' do
    it 'registers the GTFS pickup_type according to the Line' do
      vehicle_journey = vehicle_journeys.first
      vehicle_journey.line.update flexible_line_type: :other

      part.perform

      expect(index.pickup_type(vehicle_journey.id)).to be_truthy
    end
  end
end

RSpec.describe Export::Gtfs::VehicleJourneys::ServiceFinder do
  subject(:finder) { described_class.new services }
  let(:services) { [] }

  describe '#single' do
    subject { finder.single }

    let(:service) { Export::Gtfs::Service.new('test') }
    let(:services) { [service] }

    context 'when a single Service is present' do
      it 'returns this Service' do
        is_expected.to eq(service)
      end
    end

    context 'when several Services are present' do
      let(:services) { 3.times.map { double } }
      it { is_expected.to be_nil }
    end
  end

  context 'when today is 2030-01-15' do
    before { allow(finder).to receive(:today).and_return(today) }
    let(:today) { Date.parse '2030-01-15' }

    describe '#current' do
      subject { finder.current }

      context 'when no service is present' do
        it { is_expected.to be_nil }
      end

      context 'when a Service validity period includes today' do
        let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-10..2030-01-20')) }
        let(:services) { [service] }

        it { is_expected.to eq(service) }
      end

      context 'when no Service validity period includes today' do
        let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-20..2030-01-30')) }
        let(:services) { [service] }

        it { is_expected.to be_nil }
      end

      context 'when several services includes today in their validity periods' do
        let(:first) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-10..2030-01-20')) }
        let(:second) { Export::Gtfs::Service.new('second', validity_period: Period.parse('2030-01-10..2030-01-20')) }
        let(:services) { [first, second] }

        it 'returns the first one' do
          is_expected.to eq(first)
        end
      end
    end

    describe '#nexts' do
      subject { finder.nexts }

      context 'when no service is present' do
        it { is_expected.to be_empty }
      end

      context 'when a Service is before today' do
        let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-01..2030-01-10')) }
        let(:services) { [service] }

        it { is_expected.to_not include(service) }
      end

      context 'when a Service starts before today' do
        let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-01..2030-01-30')) }
        let(:services) { [service] }

        it { is_expected.to_not include(service) }
      end

      context 'when a Service starts after today' do
        let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-20..2030-01-30')) }
        let(:services) { [service] }

        it { is_expected.to include(service) }
      end

      context 'when several Service start after today' do
        let(:services) do
          3.times.map do |n|
            Export::Gtfs::Service.new("test-#{n}", validity_period: Period.parse('2030-01-20..2030-01-30'))
          end
        end
        it { is_expected.to match_array(services) }
      end
    end

    describe '#next' do
      subject { finder.next }

      before { allow(finder).to receive(:nexts).and_return(nexts) }
      let(:nexts) { [] }

      context 'when no next service is found' do
        it { is_expected.to be_nil }
      end

      context 'when several next services are found' do
        let(:first) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-20..2030-01-30')) }
        let(:second) { Export::Gtfs::Service.new('second', validity_period: Period.parse('2030-01-21..2030-01-30')) }
        let(:nexts) { [first, second] }

        it 'returns the Service with the nearest start' do
          is_expected.to eq(first)
        end
      end
    end

    describe '#preferred' do
      subject { finder.preferred }

      context 'when single is defined' do
        before { allow(finder).to receive(:single).and_return(double('single')) }
        it { is_expected.to eq(finder.single) }
      end

      context 'when single is nil' do
        before { allow(finder).to receive(:single).and_return(nil) }

        context 'when current is defined' do
          before { allow(finder).to receive(:current).and_return(double('current')) }
          it { is_expected.to eq(finder.current) }
        end

        context 'when current is nil' do
          before { allow(finder).to receive(:current).and_return(nil) }

          context 'when next is defined' do
            before { allow(finder).to receive(:next).and_return(double('next')) }
            it { is_expected.to eq(finder.next) }
          end

          context 'when next is nil' do
            before { allow(finder).to receive(:next).and_return(nil) }
            it { is_expected.to be_nil }
          end
        end
      end
    end
  end
end

RSpec.describe Export::Gtfs::VehicleJourneys::Decorator do
  let(:vehicle_journey) { Chouette::VehicleJourney.new }
  let(:index) { Export::Gtfs::Index.new }
  let(:resource_code_space) { double }
  let(:line) { Chouette::Line.new(id: rand(100)) }
  let(:accessibility_assessment) { AccessibilityAssessment.new(id: rand(100)) }

  let(:decorator) do
    described_class.new vehicle_journey, index: index # , code_provider: resource_code_space
  end

  describe '#route_id' do
    subject { decorator.route_id }

    let(:indexed_route_id) { double 'GTFS route_id associated to the VehicleJourney line' }

    before do
      vehicle_journey.route = Chouette::Route.new(line_id: line.id)
      index.register_route_id line, indexed_route_id
    end

    it { is_expected.to be(indexed_route_id) }
  end

  describe '#trip_id' do
    subject { decorator.trip_id(service) }

    let(:service) { Export::Gtfs::Service.new('service_id') }
    let(:base_trip_id) { 'base_trip_id' }

    before do
      allow(decorator).to receive(:base_trip_id).and_return(base_trip_id)
    end

    context "when the target service isn't the preferred one" do
      before { allow(decorator).to receive(:preferred_service).and_return(nil) }

      it 'uses the base trip id suffixed with service id' do
        is_expected.to eq('base_trip_id-service_id')
      end
    end

    context 'when the target service is the preferred one' do
      before { allow(decorator).to receive(:preferred_service).and_return(service) }

      it 'uses the raw base trip id' do
        is_expected.to eq(base_trip_id)
      end
    end

    describe '#trip_attributes' do
      subject { decorator.trip_attributes(service) }

      it 'uses route_id as attribute' do
        allow(decorator).to receive(:route_id).and_return(rand(100))
        is_expected.to include(route_id: decorator.route_id)
      end

      it 'uses the given Service id as attribute' do
        is_expected.to include(service_id: service.id)
      end

      it 'uses trip_id (with given service_id) as id attribute' do
        allow(decorator).to receive(:trip_id).with(service).and_return('trip_id')
        is_expected.to include(id: 'trip_id')
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

  describe '#wheelchair_accessible' do
    subject { decorator.gtfs_wheelchair_accessibility }

    before do
      accessibility_assessment.wheelchair_accessibility = wheelchair_accessibility
      allow(vehicle_journey).to receive(:accessibility_assessment).and_return(accessibility_assessment)
    end

    context "when wheelchair accessibility is 'unknown'" do
      let(:wheelchair_accessibility) { 'unknown' }

      it { is_expected.to eq '0' }
    end

    context "when wheelchair accessibility is 'yes'" do
      let(:wheelchair_accessibility) { 'yes' }

      it { is_expected.to eq '1' }
    end

    context "when wheelchair accessibility is 'no'" do
      let(:wheelchair_accessibility) { 'no' }

      it { is_expected.to eq '2' }
    end
  end

  describe '#bikes_allowed' do
    subject { decorator.gtfs_bikes_allowed }

    let(:service_facility_set) { ServiceFacilitySet.new(associated_services: associated_services) }
    let(:associated_services) { [] }

    let(:service_facility_sets) { [service_facility_set] }

    before do
      allow(vehicle_journey).to receive(:service_facility_sets).and_return(service_facility_sets)
    end

    context "when associated_services is 'luggage_carriage/cycles_allowed'" do
      let(:associated_services) { ['luggage_carriage/cycles_allowed'] }

      it { is_expected.to eq '1' }
    end

    context "when associated services is 'luggage_carriage/no_cycles'" do
      let(:associated_services) { ['luggage_carriage/no_cycles'] }

      it { is_expected.to eq '2' }
    end

    context "when associated services contains both 'luggage_carriage/cycles_allowed' and 'luggage_carriage/no_cycles'" do
      let(:associated_services) { ['luggage_carriage/cycles_allowed'] }

      before do
        service_facility_sets << ServiceFacilitySet.new(associated_services: ['luggage_carriage/no_cycles'])
      end

      it { is_expected.to eq '0' }
    end
  end

  describe '#services' do
    subject { decorator.services }

    def services(*identifiers)
      identifiers.flatten!
      identifiers.map do |identifier|
        Export::Gtfs::Service.new identifier
      end.to_set
    end

    before do
      decorator.index.register_services double(id: 1), services(%w[a b c])
      decorator.index.register_services double(id: 2), services(%w[d e f])

      allow(decorator).to receive(:time_table_ids).and_return([1, 2])
    end

    it 'returns all the GTFS service identifiers associated to Vehicle Journey TimeTable identifiers' do
      is_expected.to match_array(services(%w[a b c d e f]))
    end
  end

  describe '#direction_id' do
    subject { decorator.direction_id }

    before do
      vehicle_journey.route = Chouette::Route.new wayback: wayback
    end

    context 'when route wayback is outbound' do
      let(:wayback) { Chouette::Route.outbound }
      it { is_expected.to eq(0) }
    end

    context 'when route wayback is inbound' do
      let(:wayback) { Chouette::Route.inbound }
      it { is_expected.to eq(1) }
    end
  end

  describe '#shape_id' do
    subject { decorator.gtfs_shape_id }

    context 'when a Shape is associated to the Journey Pattern' do
      let(:indexed_shape_id) { double 'GTFS shape_id associated to the JourneyPattern Shape' }

      before do
        vehicle_journey.journey_pattern = Chouette::JourneyPattern.new(shape_id: 12)
        shape_id = vehicle_journey.journey_pattern.shape_id

        allow(decorator.code_provider).to receive_message_chain(:shapes,:code).with(shape_id) { indexed_shape_id }
      end

      it { is_expected.to be(indexed_shape_id) }
    end

    context 'when no Shape is associated to the Journey Pattern' do
      before do
        vehicle_journey.journey_pattern = Chouette::JourneyPattern.new
      end

      it { is_expected.to be_nil }
    end
  end

  describe 'gtfs_headsign' do
    subject { decorator.gtfs_headsign }

    context 'when JourneyPattern published_name is "dummy"' do
      before { allow(decorator).to receive(:journey_pattern).and_return(double(published_name: 'dummy')) }
      it { is_expected.to eq('dummy') }
    end
  end
end
