# frozen_string_literal: true

RSpec.describe Control::GeographicalZone do
  subject(:control) { described_class.new }

  it { is_expected.to enumerize(:target_model).in('StopArea', 'Entrance', 'PointOfInterest') }
  it { is_expected.to validate_presence_of(:target_model) }
  it { is_expected.to validate_presence_of(:upper_left_input) }
  it { is_expected.to validate_presence_of(:lower_right_input) }

  it { is_expected.to allow_value('48.8559324,2.2940166').for(:upper_left_input) }
  it { is_expected.to allow_value('48.8559324,2.2940166').for(:lower_right_input) }

  describe '#upper_left' do
    subject { control.upper_left }

    context 'when upper_left_input is "48.85593,2.29401"' do
      before do
        control.upper_left_input = '48.85593,2.29401'
        control.validate
      end

      it { is_expected.to eq('POINT(2.29401 48.85593)') }
    end
  end

  describe '#lower_right' do
    subject { control.lower_right }

    context 'when lower_right_input is "48.85593,2.29401"' do
      before do
        control.lower_right_input = '48.85593,2.29401'
        control.validate
      end

      it { is_expected.to eq('POINT(2.29401 48.85593)') }
    end
  end

  describe '.permitted_params' do
    subject { described_class.permitted_params }

    it { is_expected.to include(:upper_left_input) }
    it { is_expected.to include(:lower_right_input) }
    it { is_expected.to_not include(:upper_left) }
    it { is_expected.to_not include(:lower_right) }
  end
end

RSpec.describe Control::GeographicalZone::Run do
  subject(:control_run) { described_class.new }

  describe '#bounds' do
    subject { control_run.bounds }

    context 'when upper_left is POINT(0 0) and lower_right is POINT(1 1)' do
      before do
        control_run.upper_left = 'POINT(0 0)'
        control_run.lower_right = 'POINT(1 1)'
      end

      it do
        is_expected.to eq "ST_SetSRID(ST_MakeBox2D(ST_GeomFromText('POINT(0 0)'), ST_GeomFromText('POINT(1 1)')), 4326)"
      end
    end
  end

  describe '#position' do
    subject { control_run.position }

    context 'when target_model is StopArea' do
      before { control_run.target_model = 'StopArea' }

      it { is_expected.to eq 'ST_SetSRID(ST_Point(longitude, latitude), 4326)' }
    end

    context 'when target_model is Entrance' do
      before { control_run.target_model = 'Entrance' }

      it { is_expected.to eq 'position' }
    end

    context 'when target_model is PointOfInterest' do
      before { control_run.target_model = 'PointOfInterest' }

      it { is_expected.to eq 'position' }
    end
  end

  describe '#run' do

    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:control_run) do
      Control::GeographicalZone::Run.create(
        control_list_run: control_list_run,
        target_model: target_model,
        criticity: 'warning',
        upper_left_input: '0,0',
        lower_right_input: '2,2',
        position: 0
      )
    end

    let(:context) do
      Chouette.create do
        stop_area :stop_area_inside_bounds, latitude: 1, longitude: 1
        entrance :entrance_inside_bounds
        point_of_interest :poi_inside_bounds

        stop_area :stop_area_outside_bounds, latitude: 3, longitude: 3
        entrance :entrance_outside_bounds
        point_of_interest :poi_outside_bounds

        referential
      end
    end

    let(:referential) { context.referential }
    let(:workbench) { context.workbench }
    let(:journey_pattern) { context.journey_pattern }

    describe '#StopArea' do
      before {control_run.run}

      let(:target_model) { 'StopArea' }
      let(:stop_area_inside_bounds) { context.stop_area(:stop_area_inside_bounds) }
      let(:stop_area_outside_bounds) { context.stop_area(:stop_area_outside_bounds) }

      let(:expected_message) do
        an_object_having_attributes(
          source: stop_area_outside_bounds,
          criticity: 'warning',
        )
      end

      let(:not_expected_message) do
        an_object_having_attributes(
          source: stop_area_inside_bounds,
          criticity: 'warning',
        )
      end

      it do
        expect(control_run.control_messages).to include(expected_message)
        expect(control_run.control_messages).not_to include(not_expected_message)
      end
    end

    describe '#Entrance' do
      before do
        entrance_inside_bounds.update_attribute :position, 'POINT(1 1)'
        entrance_outside_bounds.update_attribute :position, 'POINT(3 3)'

        control_run.run
      end

      let(:target_model) { 'Entrance' }
      let(:entrance_inside_bounds) { context.entrance(:entrance_inside_bounds) }
      let(:entrance_outside_bounds) { context.entrance(:entrance_outside_bounds) }

      let(:expected_message) do
        an_object_having_attributes(
          source: entrance_outside_bounds,
          criticity: 'warning',
        )
      end

      let(:not_expected_message) do
        an_object_having_attributes(
          source: entrance_inside_bounds,
          criticity: 'warning',
        )
      end

      it do
        expect(control_run.control_messages).to include(expected_message)
        expect(control_run.control_messages).not_to include(not_expected_message)
      end
    end

    describe '#PointOfInterest' do
      before do
        poi_inside_bounds.update_attribute :position, 'POINT(1 1)'
        poi_outside_bounds.update_attribute :position, 'POINT(3 3)'

        control_run.run
      end

      let(:target_model) { 'PointOfInterest' }
      let(:poi_inside_bounds) { context.point_of_interest(:poi_inside_bounds) }
      let(:poi_outside_bounds) { context.point_of_interest(:poi_outside_bounds) }

      let(:expected_message) do
        an_object_having_attributes(
          source: poi_outside_bounds,
          criticity: 'warning',
        )
      end

      let(:not_expected_message) do
        an_object_having_attributes(
          source: poi_inside_bounds,
          criticity: 'warning',
        )
      end

      it do
        expect(control_run.control_messages).to include(expected_message)
        expect(control_run.control_messages).not_to include(not_expected_message)
      end
    end
  end
end
