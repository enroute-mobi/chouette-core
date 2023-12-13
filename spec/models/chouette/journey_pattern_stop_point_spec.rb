# frozen_string_literal: true

RSpec.describe Chouette::JourneyPatternStopPoint do
  describe '.table_name' do
    subject { described_class.table_name }

    it { is_expected.to eq('journey_patterns_stop_points') }
  end
end
