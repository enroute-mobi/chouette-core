# frozen_string_literal: true

RSpec.describe TimeOfDayInput do
  subject(:input) { TimeOfDayInput.new(builder, :dummy, :dummy, :text) }

  let(:builder) { double(object: double) }

  describe '#day_offsets' do
    subject { input.day_offsets }

    it do
      expected_values = [0, 1, 2, 3, 4, 5].map do |value|
        an_object_having_attributes(value: value)
      end
      is_expected.to contain_exactly(*expected_values)
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
