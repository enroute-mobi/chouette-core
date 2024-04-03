# frozen_string_literal: true

RSpec.describe Policy::TimeTable, type: :policy do
  let(:resource) { build_stubbed(:time_table) }

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end

  describe '#duplicate?' do
    subject { policy.duplicate? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }

    let(:referential_policy_create_time_table) { true }

    before do
      fk_policy = double
      expect(fk_policy).to receive(:create?).with(Chouette::TimeTable).and_return(referential_policy_create_time_table)
      expect(Policy::Referential).to(
        receive(:new).with(resource.referential, context: policy_context).and_return(fk_policy)
      )
    end

    it do
      expect(policy).to receive(:around_can).with(:duplicate).and_call_original
      is_expected.to be_truthy
    end

    context 'when a time table cannot be created from a referential' do
      let(:referential_policy_create_time_table) { false }
      it { is_expected.to eq(false) }
    end
  end
end
