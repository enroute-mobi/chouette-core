# frozen_string_literal: true

RSpec.describe Policy::Workgroup, type: :policy do
  let(:policy_context_class) { Policy::Context::User }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_falsy }

    context 'Aggregate' do
      let(:resource_class) { Aggregate }

      it { applies_strategy(Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }
    end

    context 'PublicationSetup' do
      let(:resource_class) { PublicationSetup }

      it { applies_strategy(Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }
    end

    context 'DocumentType' do
      let(:resource_class) { DocumentType }

      it { does_not_apply_strategy(Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }
    end

    context 'Workbench' do
      let(:resource_class) { Workbench }

      it { does_not_apply_strategy(Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }
    end

    context 'ProcessingRule::Workgroup' do
      let(:resource_class) { ProcessingRule::Workgroup }

      it { does_not_apply_strategy(Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }
    end

    context 'PublicationApi' do
      let(:resource_class) { PublicationApi }

      it { does_not_apply_strategy(Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }
    end

    context 'CodeSpace' do
      let(:resource_class) { CodeSpace }

      it { does_not_apply_strategy(Policy::Strategy::Permission, :update) }

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

    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end

  describe '#add_workbench?' do
    subject { policy.add_workbench? }

    let(:policy_create_workbench) { true }

    before { allow(policy).to receive(:create?).with(Workbench).and_return(policy_create_workbench) }

    it { does_not_apply_strategy(Policy::Strategy::Permission, :add_workbench) }

    it do
      allow(policy).to receive(:around_can).and_call_original
      expect(policy).to receive(:around_can).with(:add_workbench).and_call_original
      is_expected.to be_truthy
    end

    context 'when user cannot create workbench' do
      let(:policy_create_workbench) { false }
      it { is_expected.to be_falsy }
    end
  end
end
