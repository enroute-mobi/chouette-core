# frozen_string_literal: true

RSpec.describe Cron::CheckNightlyAggregatesJob do
  it { is_expected.to be_a_kind_of(Cron::MinutesJob) }
end
