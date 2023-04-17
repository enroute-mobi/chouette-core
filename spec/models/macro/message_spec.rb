# frozen_string_literal: true

RSpec.describe Macro::Message do
  let(:message) { Macro::Message.new }

  describe '.table_name' do
    subject { described_class.table_name }
    it { is_expected.to eq('public.macro_messages') }
  end

  describe '#i18n_target_model' do
    subject { message.i18n_target_model }

    context 'when source type is not defined' do
      before { message.source_type = nil }

      it { is_expected.to be_nil }
    end

    context 'when source type is "Chouette::VehicleJourney"' do
      before { message.source_type = 'Chouette::VehicleJourney' }

      it { is_expected.to eq 'course' }
    end
  end
end
