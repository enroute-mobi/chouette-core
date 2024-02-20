# frozen_string_literal: true

RSpec.describe Policy::DocumentMembership, type: :policy do
  describe '#destroy?' do
    subject { policy.destroy? }

    let(:context) do
      Chouette.create do
        document
      end
    end
    let(:document) { context.document }
    let(:resource) { document.memberships.new(documentable: documentable) }

    let(:documentable_policy_update) { true }

    before do
      dbl = double(update?: documentable_policy_update)
      allow(documentable_policy_class).to receive(:new).with(documentable, context: policy_context).and_return(dbl)
    end

    context 'with Chouette::Company' do
      let(:documentable) { build_stubbed(:company) }
      let(:documentable_policy_class) { Policy::Company }

      it { applies_strategy(Policy::Strategy::Permission, :destroy) }

      it { is_expected.to be_truthy }

      context 'when the company cannot be updated' do
        let(:documentable_policy_update) { false }
        it { is_expected.to be_falsy }
      end
    end

    context 'with Chouette::Line' do
      let(:documentable) { build_stubbed(:line) }
      let(:documentable_policy_class) { Policy::Line }

      it { applies_strategy(Policy::Strategy::Permission, :destroy) }

      it { is_expected.to be_truthy }

      context 'when the line cannot be updated' do
        let(:documentable_policy_update) { false }
        it { is_expected.to be_falsy }
      end
    end

    context 'with Chouette::StopArea' do
      let(:documentable) { build_stubbed(:stop_area) }
      let(:documentable_policy_class) { Policy::StopArea }

      it { applies_strategy(Policy::Strategy::Permission, :destroy) }

      it { is_expected.to be_truthy }

      context 'when the stop area cannot be updated' do
        let(:documentable_policy_update) { false }
        it { is_expected.to be_falsy }
      end
    end
  end
end
