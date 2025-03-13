# frozen_string_literal: true

RSpec.describe Export::Gtfs::Lines::Decorator do
  let(:line) { Chouette::Line.new }
  let(:decorator) { described_class.new line }

  describe '#route_type' do
    subject { decorator.route_type }

    context "when extended gtfs route types aren't ignored" do
      before { allow(decorator).to receive(:ignore_extended_gtfs_route_types).and_return(false) }

      {
        tram: 0,
        metro: 1,
        rail: 2,
        bus: 3,
        water: 4,
        'funicular/street_cable_car': 5,
        telecabin: 6,
        funicular: 7,
        trolley_bus: 11,
        'rail/monorail': 12,
        coach: 200,
        air: 1100,
        taxi: 1500,
        hireCar: 1506,
        'rail/interregional_rail': 103,
        'coach/regional_coach': 204,
        'coach/special_coach': 205,
        'coach/commuter_coach': 208,
        'bus/school_and_public_service_bus': 713
      }.each do |transport_mode, expected_route|
        transport_mode = Chouette::TransportMode.from(transport_mode)

        context "when Line transport mode is #{transport_mode}" do
          before { line.chouette_transport_mode = transport_mode }

          it { is_expected.to eq(expected_route) }
        end
      end

      context 'when Line is flexible' do
        before { allow(line).to receive(:flexible_service?).and_return(true) }

        it { is_expected.to eq(715)  }
      end

      context "when Line transport mode isn't supported (like 'dummy')" do
        before { line.transport_mode = :dummy }

        it { is_expected.to be_nil }
      end
    end

    context 'when extended gtfs route types are ignored' do
      before { allow(decorator).to receive(:ignore_extended_gtfs_route_types).and_return(true) }

      {
        tram: 0,
        metro: 1,
        rail: 2,
        bus: 3,
        water: 4,
        'funicular/street_cable_car': 5,
        telecabin: 6,
        funicular: 7,
        trolley_bus: 11,
        'rail/monorail': 12,
        coach: 3,
        air: 1100,
        taxi: 1500,
        hireCar: 1506,
        'rail/interregional_rail': 2,
        'coach/regional_coach': 3,
        'coach/special_coach': 3,
        'coach/commuter_coach': 3,
        'bus/school_and_public_service_bus': 3
      }.each do |transport_mode, expected_route|
        transport_mode = Chouette::TransportMode.from(transport_mode)

        context "when Line transport mode is #{transport_mode}" do
          before { line.chouette_transport_mode = transport_mode }

          it { is_expected.to eq(expected_route) }

          context 'when Line is flexible' do
            before { allow(line).to receive(:flexible_service?).and_return(true) }

            it { is_expected.to eq(expected_route) }
          end
        end
      end

      context "when Line transport mode isn't supported (like 'dummy')" do
        before { line.transport_mode = :dummy }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#route_long_name' do
    subject { decorator.route_long_name }

    context 'when Line#published_name is "test"' do
      before { line.published_name = 'test' }

      it { is_expected.to eq(line.published_name) }
    end

    context 'when Line#published_name is no defined' do
      context 'when Line#name is "test"' do
        before { line.name = 'test' }

        it { is_expected.to eq(line.name) }
      end
    end

    context 'when the candidate value is the route_short_name value' do
      before do
        allow(decorator).to receive(:route_short_name).and_return('test')
        line.published_name = decorator.route_short_name
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#route_agency_id' do
    subject { decorator.route_agency_id }

    context 'when Company is associated to code "42"' do
      before do
        line.company_id = 12
        allow(decorator.code_provider).to receive_message_chain(:companies, :code).with(line.company_id) { '42' }
      end

      it { is_expected.to eq('42') }
    end

    context 'when Company is not associated to a code' do
      it { is_expected.to eq(Export::Gtfs::DEFAULT_AGENCY_ID) }
    end
  end

  describe 'default_agency?' do
    subject { decorator.default_agency? }

    context "when route_agency_id is #{Export::Gtfs::DEFAULT_AGENCY_ID}" do
      before { allow(decorator).to receive(:route_agency_id) { Export::Gtfs::DEFAULT_AGENCY_ID } }

      it { is_expected.to be_truthy }
    end

    context "when route_agency_id is 'dummy'" do
      before { allow(decorator).to receive(:route_agency_id) { 'dummy' } }

      it { is_expected.to be_falsy }
    end
  end

  describe '#gtfs_attributes' do
    subject { decorator.gtfs_attributes }

    %i[short_name long_name].each do |route_attribute|
      attribute = "route_#{route_attribute}".to_sym

      it "uses #{attribute} method to fill associated attribute #{route_attribute}" do
        allow(decorator).to receive(attribute).and_return('test')
        route_attribute = attribute.to_s.gsub(/^route_/, '').to_sym

        is_expected.to include(route_attribute => decorator.send(attribute))
      end
    end

    %i[url color text_color].each do |attribute|
      it "uses Line #{attribute} to fill the attribute #{attribute}" do
        allow(line).to receive(attribute).and_return('test')

        is_expected.to include(attribute => line.send(attribute))
      end
    end
  end

  describe '#validate' do
    subject { decorator.validate }

    context 'when the candidate route_agency_id is the default agency' do
      before { allow(decorator).to receive(:default_agency?).and_return(true) }

      it { expect { subject }.to change(decorator, :messages).from(be_empty).to(be_one) }

      describe 'the message' do
        subject { decorator.messages.first }

        before { decorator.validate }

        it { is_expected.to have_attributes(message_key: :no_company) }
      end
    end
  end
end
