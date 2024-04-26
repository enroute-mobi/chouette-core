# frozen_string_literal: true

RSpec.describe Policy::Referential, type: :policy do
  let(:resource) { referential }
  let(:policy_context_class) { Policy::Context::Referential }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { does_not_apply_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }

    it { is_expected.to be_falsy }

    context 'Chouette::TimeTable' do
      let(:resource_class) { Chouette::TimeTable }
      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }

    context 'when the referential is not ready' do
      before { referential.ready = false }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is finalised' do
      before { referential.referential_suite_id = random_int }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is archived' do
      before { referential.archived_at = 42.seconds.ago }
      it { is_expected.to be_falsy }
    end
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }

    context 'when the referential is not ready' do
      before { referential.ready = false }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is finalised' do
      before { referential.referential_suite_id = random_int }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is merged' do
      before { referential.merged_at = 42.seconds.ago }
      it { is_expected.to be_falsy }
    end
  end

  describe '#browse?' do
    subject { policy.browse? }

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { does_not_apply_strategy(Policy::Strategy::Workbench) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }

    it do
      expect(policy).to receive(:around_can).with(:browse).and_call_original
      is_expected.to be_truthy
    end

    context 'when the referential is not ready' do
      before { referential.ready = false }
      it { is_expected.to be_falsy }

      context 'but archived' do
        before { referential.archived_at = 42.seconds.ago }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#clone?' do
    subject { policy.clone? }

    let(:workbench_policy_create_referential) { true }

    before do
      dbl = double
      allow(dbl).to receive(:create?).with(Referential).and_return(workbench_policy_create_referential)
      allow(Policy::Workbench).to receive(:new).with(referential.workbench, context: policy_context).and_return(dbl)
    end

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { does_not_apply_strategy(Policy::Strategy::Workbench) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }

    it do
      expect(policy).to receive(:around_can).with(:clone).and_call_original
      is_expected.to be_truthy
    end

    context 'when the referential is not ready' do
      before { referential.ready = false }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is finalised' do
      before { referential.referential_suite_id = random_int }
      it { is_expected.to be_falsy }
    end

    context 'when the user cannot create a referential from a workbench' do
      let(:workbench_policy_create_referential) { false }
      it { is_expected.to be_falsy }
    end
  end

  describe '#validate?' do
    subject { policy.validate? }

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Workbench) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }

    it do
      expect(policy).to receive(:around_can).with(:validate).and_call_original
      is_expected.to be_truthy
    end

    context 'when the referential is not ready' do
      before { referential.ready = false }
      it { is_expected.to be_falsy }
    end
  end

  describe '#archive?' do
    subject { policy.archive? }

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Workbench) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :archive) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it do
      allow(policy).to receive(:around_can).and_call_original
      expect(policy).to receive(:around_can).with(:archive).and_call_original
      is_expected.to be_truthy
    end

    context 'when the referential is not ready' do
      before { referential.ready = false }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is finalised' do
      before { referential.referential_suite_id = random_int }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is archived' do
      before { referential.archived_at = 42.seconds.ago }
      it { is_expected.to be_falsy }
    end

    context 'with Empty context' do
      let(:policy_context_class) { Policy::Context::Empty }
      it { is_expected.to be_falsy }
    end
  end

  describe '#unarchive?' do
    subject { policy.unarchive? }

    before { referential.archived_at = 42.seconds.ago }

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Workbench) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :unarchive) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it do
      allow(policy).to receive(:around_can).and_call_original
      expect(policy).to receive(:around_can).with(:unarchive).and_call_original
      is_expected.to be_truthy
    end

    context 'when the referential is not ready' do
      before { referential.ready = false }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is archived' do
      before { referential.archived_at = nil }
      it { is_expected.to be_falsy }
    end

    context 'when the referential is merged' do
      before { referential.merged_at = 42.seconds.ago }
      it { is_expected.to be_falsy }
    end

    context 'with Empty context' do
      let(:policy_context_class) { Policy::Context::Empty }
      it { is_expected.to be_falsy }
    end
  end

  describe '#flag_urgent?' do
    subject { policy.flag_urgent? }

    it { does_not_apply_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :flag_urgent) }

    it do
      expect(policy).to receive(:around_can).with(:flag_urgent).and_call_original
      is_expected.to be_truthy
    end
  end
end
