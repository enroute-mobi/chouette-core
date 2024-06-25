# frozen_string_literal: true

RSpec.describe Policy::LineNoticeMembershipCollection, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:line) { Chouette.create { line }.line }
  let(:resource) { line.line_notice_memberships }

  describe '.permission_exceptions' do
    subject { described_class.permission_exceptions }

    it do
      is_expected.to eq(
        {
          update: 'line_notice_memberships.destroy'
        }
      )
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(::Policy::Strategy::Permission, :update) }

    let(:policy_line_update) { true }
    let(:policy_line_notice_membership_create) { true }

    before do
      fk_policy = double
      allow(fk_policy).to receive(:update?).and_return(policy_line_update)
      allow(fk_policy).to(
        receive(:create?).with(Chouette::LineNoticeMembership).and_return(policy_line_notice_membership_create)
      )
      allow(Policy::Line).to receive(:new).with(line, context: policy_context).and_return(fk_policy)
    end

    it { is_expected.to be_truthy }

    context 'when the user cannot update a line' do
      let(:policy_line_update) { false }
      it { is_expected.to be_falsy }
    end

    context 'when the user cannot create a line notice membership' do
      let(:policy_line_notice_membership_create) { false }
      it { is_expected.to be_falsy }
    end
  end
end
