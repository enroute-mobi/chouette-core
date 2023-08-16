# frozen_string_literal: true

RSpec.describe TimeOfDayInput::SelectDayOffset do
  subject(:select) { TimeOfDayInput::SelectDayOffset.new('dummy') }

  describe '#day_offsets' do
    subject { select.day_offsets }

    it do
      expected_values = [0, 1, 2, 3, 4, 5].map do |value|
        an_object_having_attributes(value: value)
      end
      is_expected.to contain_exactly(*expected_values)
    end
  end

  describe '#id' do
    subject { select.id }

    context 'when name is control_list[controls_attributes][0][after(4i)]' do
      before { allow(select).to receive(:name).and_return('control_list[controls_attributes][0][after(4i)]') }

      it { is_expected.to eq('control_list_controls_attributes_0_after_4i') }
    end
  end
end

RSpec.describe TimeOfDayInput::DayOffset do
  describe '#name' do
    subject { day_offset.name }

    context 'when value is 1' do
      let(:day_offset) { TimeOfDayInput::DayOffset.new(1) }

      context 'when locale is :fr' do
        around { |example| I18n.with_locale(:fr) { example.run } }
        it { is_expected.to eq('J+1') }
      end

      context 'when locale is :en' do
        around { |example| I18n.with_locale(:en) { example.run } }
        it { is_expected.to eq('D+1') }
      end
    end
  end
end
