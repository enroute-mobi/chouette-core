# frozen_string_literal: true

RSpec.describe Policy::LineNoticeMembershipCollection, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:line) { Chouette.create { line }.line }
  let(:resource) { line.line_notice_memberships }

  describe '#update?' do
    subject { policy.update? }

    let(:policy_line_update) { true }

    before do
      fk_policy = double
      expect(fk_policy).to receive(:update?).and_return(policy_line_update)
      expect(Policy::Line).to receive(:new).with(line, context: policy_context).and_return(fk_policy)
    end

    it { is_expected.to be_truthy }

    context 'when the user cannot update a line' do
      let(:policy_line_update) { false }
      it { is_expected.to be_falsy }
    end
  end
end
