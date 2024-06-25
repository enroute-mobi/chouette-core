# frozen_string_literal: true

RSpec.describe Policy::LineNoticeMembership, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:resource) { double(:line_notice_membership, line: double(:line)) }

  describe '#update?' do
    subject { policy.update? }

    it { is_expected.to be_falsy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(::Policy::Strategy::Permission, :destroy) }

    let(:policy_line_update) { true }

    before do
      fk_policy = double
      expect(fk_policy).to receive(:update?).and_return(policy_line_update)
      expect(Policy::Line).to receive(:new).with(resource.line, context: policy_context).and_return(fk_policy)
    end

    it { is_expected.to be_truthy }

    context 'when the user cannot update a line' do
      let(:policy_line_update) { false }
      it { is_expected.to be_falsy }
    end
  end
end
