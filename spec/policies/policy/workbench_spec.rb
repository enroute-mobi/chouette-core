# frozen_string_literal: true

RSpec.describe Policy::Workbench, type: :policy do
  let(:resource) { build_stubbed(:workbench) }
  let(:policy_context_class) { Policy::Context::User }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }

    it { is_expected.to be_falsy }

    context 'Referential' do
      let(:resource_class) { Referential }
      it { is_expected.to be_truthy }
    end

    context 'DocumentProvider' do
      let(:resource_class) { DocumentProvider }
      it { is_expected.to be_truthy }
    end

    context 'Document' do
      let(:resource_class) { Document }
      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { is_expected.to be_falsy }
  end
end
