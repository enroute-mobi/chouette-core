# frozen_string_literal: true

RSpec.describe RouteObserver do
  context '.observed_classes' do
    subject { described_class.observed_classes }

    it { is_expected.to match_array([Chouette::Route]) }
  end
end
