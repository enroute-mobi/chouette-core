# frozen_string_literal: true

RSpec.describe Policy::PermitAll do
  subject(:policy) { Policy::PermitAll.new(resource) }

  let(:resource) { double }

  describe '#can?' do
    subject { policy.can?(:dummy) }

    it { is_expected.to be_truthy }
  end
end
