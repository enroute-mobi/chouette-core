# frozen_string_literal: true

RSpec.describe Export::Gtfs::VehicleJourneyAtStops do
  subject(:part) { Export::Gtfs::VehicleJourneyAtStops.new(export) }
  let(:export) { Export::Gtfs.new export_scope: export_scope }
  let(:export_scope) { double }

  describe '#ignore_time_zone?' do
    subject { part.ignore_time_zone? }

    let(:context) do
      Chouette.create do
        5.times { stop_area }
      end
    end

    let(:export_scope) { double stop_areas: context.stop_area_referential.stop_areas }

    context 'when no scoped StopAreas has a timezone' do
      it { is_expected.to be_truthy }
    end

    context 'when one of the StopAreas has a timezone' do
      before { export_scope.stop_areas.sample.update time_zone: 'Europe/London' }

      it { is_expected.to be_falsy }
    end
  end

  describe '#default_timezone' do
    context 'without ignore_time_zone?' do
      before do
        allow(export).to receive(:default_timezone) { 'Europe/Madrid' }
        allow(part).to receive(:ignore_time_zone?) { false }
      end

      it { is_expected.to have_same_attributes(:default_timezone, than: export) }
    end

    context 'when ignore_time_zone?' do
      before { allow(part).to receive(:ignore_time_zone?) { true } }

      it { is_expected.to have_attributes(default_timezone: be_nil) }
    end
  end
end

RSpec.describe Export::Gtfs::VehicleJourneyAtStops::Decorator do
  let(:light_vehicle_journey_at_stop) { Chouette::VehicleJourneyAtStop::Light::VehicleJourneyAtStop.new }

  subject(:decorator) { described_class.new light_vehicle_journey_at_stop }

  describe '#timezone' do
    subject { decorator.time_zone }

    context 'when default_timezone is "Europe/Berlin"' do
      before { decorator.default_timezone = 'Europe/Berlin' }

      it { is_expected.to eq(decorator.default_timezone) }
    end
  end

  %w[arrival departure].each do |state|
    describe "##{state}_time_of_day" do
      subject { decorator.send "#{state}_time_of_day" }

      context "when #{state}_time is nil" do
        before { light_vehicle_journey_at_stop.send("#{state}_time=", nil) }

        it { is_expected.to be_nil }
      end

      context "when #{state}_time is 14:00" do
        before { light_vehicle_journey_at_stop.send("#{state}_time=", '14:00') }

        it { is_expected.to eq(TimeOfDay.new(14)) }

        context "when #{state}_day_offset is 1" do
          before { light_vehicle_journey_at_stop.send("#{state}_day_offset=", 1) }

          it { is_expected.to eq(TimeOfDay.new(14, day_offset: 1)) }
        end
      end
    end

    describe "##{state}_local_time_of_day" do
      subject { decorator.send "#{state}_local_time_of_day" }

      context "when #{state}_time is nil" do
        before { light_vehicle_journey_at_stop.send("#{state}_time=", nil) }

        it { is_expected.to be_nil }
      end

      context "when #{state}_time_of_day is nil" do
        before { allow(decorator).to receive("#{state}_time_of_day").and_return(nil) }

        it { is_expected.to be_nil }
      end

      context "when #{state}_time_of_day is defined" do
        let(:time_of_day) { TimeOfDay.new(14) }
        before { allow(decorator).to receive("#{state}_time_of_day").and_return(time_of_day) }

        context 'when time_zone is defined' do
          let(:time_zone) { 'Europe/Paris' }
          before { allow(decorator).to receive(:time_zone).and_return(time_zone) }

          it "returns #{state}_time_of_day with time_zone offset" do
            is_expected.to eq(time_of_day.with_utc_offset(1.hour))
          end
        end

        context 'when time_zone is not defined' do
          before { allow(decorator).to receive(:time_zone).and_return(nil) }

          it "returns #{state}_time_of_day unchanged" do
            is_expected.to eq(time_of_day)
          end
        end
      end
    end

    describe "#stop_time_#{state}_time" do
      subject { decorator.send "stop_time_#{state}_time" }

      context "when #{state}_local_time_of_day is nil" do
        before { allow(decorator).to receive("#{state}_time_of_day").and_return(nil) }

        it { is_expected.to be_nil }
      end

      context "when #{state}_local_time_of_day is defined" do
        let(:time_of_day) { TimeOfDay.new(14) }
        before { allow(decorator).to receive("#{state}_local_time_of_day").and_return(time_of_day) }

        it "returns a GTFS::Time string representation based on #{state}_local_time_of_day value" do
          is_expected.to eq('14:00:00')
        end
      end
    end
  end

  describe '#stop_area_id' do
    subject { decorator.stop_area_id }

    context 'when VehicleJourneyAtStop defines a specific stop (stop_area_id = 42)' do
      before { light_vehicle_journey_at_stop.stop_area_id = 42 }

      it { is_expected.to eq(42) }
    end

    context 'when VehicleJourneyAtStop has no specific stop but a StopPoint (parent_stop_area_id = 42)' do
      before { allow(light_vehicle_journey_at_stop).to receive(:parent_stop_area_id).and_return(42) }

      it { is_expected.to eq(42) }
    end
  end

  describe '#drop_off_type' do
    subject { decorator.drop_off_type }

    context 'when for_alighting is forbidden' do
      before { allow(light_vehicle_journey_at_stop).to receive(:for_alighting).and_return('forbidden') }

      it { is_expected.to eq(1) }
    end

    context 'when for_alighting is not forbidden' do
      before { allow(light_vehicle_journey_at_stop).to receive(:for_alighting).and_return(nil) }

      it { is_expected.to be_zero }
    end
  end

  describe '#pickup_type' do
    subject { decorator.pickup_type }

    context 'when for_boarding is forbidden' do
      before { allow(light_vehicle_journey_at_stop).to receive(:for_boarding).and_return('forbidden') }

      it { is_expected.to eq(1) }
    end

    context 'when for_boarding is not forbidden' do
      before { allow(light_vehicle_journey_at_stop).to receive(:for_boarding).and_return(nil) }

      it { is_expected.to be_zero }
    end
  end

  describe '#stop_time_stop_id' do
    subject { decorator.stop_time_stop_id }

    context 'when stop_area_id is associated by CodeProvider to 42' do
      before do
        allow(decorator).to receive(:stop_area_id).and_return(12)
        allow(decorator.code_provider).to receive_message_chain(:stop_areas, :code).with(decorator.stop_area_id) {
                                            '42'
                                          }
      end

      it { is_expected.to eq('42') }
    end
  end

  describe '#gtfs_attributes' do
    subject { decorator.gtfs_attributes }

    before do
      allow(decorator).to receive(:position).and_return(0)
      allow(decorator).to receive(:pickup_type).and_return(0)
      allow(decorator).to receive(:drop_off_type).and_return(0)
      allow(decorator).to receive(:shape_dist_traveled).and_return(100)
    end

    %i[departure_time arrival_time stop_id].each do |stop_time_attribute|
      attribute = "stop_time_#{stop_time_attribute}".to_sym
      stop_time_attribute = attribute.to_s.gsub(/^stop_time_/, '').to_sym

      before { allow(decorator).to receive(attribute).and_return('dummy') }

      it "uses #{attribute} method to fill associated attribute (#{stop_time_attribute})" do
        is_expected.to include(stop_time_attribute => 'dummy')
      end
    end

    it 'uses position to fill the same stop_sequence attribute' do
      allow(decorator).to receive(:position).and_return(42)
      is_expected.to include(stop_sequence: decorator.position)
    end
  end
end
