# frozen_string_literal: true

RSpec.describe Policy::Line, type: :policy do
  let(:resource) { build_stubbed(:line) }
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:policy_context_class) { Policy::Context::Referential }
    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::LineProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::Referential) }

    it { is_expected.to be_falsy }

    context 'DocumentMembership' do
      let(:resource_class) { ::DocumentMembership }

      it { applies_strategy(Policy::Strategy::LineProvider) }
      it { applies_strategy(::Policy::Strategy::Permission, :create, ::DocumentMembership) }
      it { does_not_apply_strategy(Policy::Strategy::Referential) }
      it { applies_strategy(::Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }

      context 'with Workbench context' do
        let(:policy_context_class) { Policy::Context::Workbench }
        it { is_expected.to be_truthy }
      end
    end

    context 'Chouette::LineNotice' do
      let(:resource_class) { Chouette::LineNotice }

      it { applies_strategy(Policy::Strategy::LineProvider) }
      it { applies_strategy(::Policy::Strategy::Permission, :create, Chouette::LineNotice) }
      it { does_not_apply_strategy(Policy::Strategy::Referential) }

      it { is_expected.to be_truthy }

      context 'with Workbench context' do
        let(:policy_context_class) { Policy::Context::Workbench }
        it { is_expected.to be_truthy }
      end
    end

    context 'with Chouette::Route' do
      let(:resource_class) { Chouette::Route }

      it { applies_strategy(Policy::Strategy::LineProvider) }
      it { applies_strategy(Policy::Strategy::Permission, :create, Chouette::Route) }
      it { applies_strategy(Policy::Strategy::Referential) }

      it { is_expected.to be_truthy }

      context 'with Workbench context' do
        let(:policy_context_class) { Policy::Context::Workbench }
        it { is_expected.to be_falsy }
      end
    end

    context 'with Chouette::RoutingConstraintZone' do
      let(:resource_class) { Chouette::RoutingConstraintZone }

      it { applies_strategy(Policy::Strategy::LineProvider) }
      it { applies_strategy(Policy::Strategy::Permission, :create, Chouette::RoutingConstraintZone) }
      it { applies_strategy(Policy::Strategy::Referential) }

      it { is_expected.to be_truthy }

      context 'with Workbench context' do
        let(:policy_context_class) { Policy::Context::Workbench }
        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::LineProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }
    it { does_not_apply_strategy(Policy::Strategy::Referential) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::LineProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }
    it { does_not_apply_strategy(Policy::Strategy::Referential) }

    it { is_expected.to be_truthy }
  end

  describe '#attach?' do
    subject { policy.attach?(resource_class) }

    let(:resource_class) { double }

    it { does_not_apply_strategy(Policy::Strategy::LineProvider) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :apply) }
    it { does_not_apply_strategy(Policy::Strategy::Referential) }

    it do
      expect(policy).to receive(:around_can).with(:attach).and_call_original
      is_expected.to be_falsy
    end

    context 'with Chouette::LineNotice' do
      let(:resource_class) { Chouette::LineNotice }

      let(:policy_line_notice_update) { true }

      before do
        fk_policy = double
        expect(fk_policy).to receive(:update?).and_return(policy_line_notice_update)
        expect(Policy::LineNotice).to receive(:new).with(
          an_object_having_attributes(
            line_referential: resource.line_referential,
            line_provider: resource.line_provider
          ),
          context: policy_context
        ).and_return(fk_policy)
      end

      it { is_expected.to be_truthy }

      context 'when the user cannot update a line notice' do
        let(:policy_line_notice_update) { false }
        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#update_activation_dates?' do
    subject { policy.update_activation_dates? }

    it { applies_strategy(Policy::Strategy::LineProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :update_activation_dates) }
    it { does_not_apply_strategy(Policy::Strategy::Referential) }

    it do
      expect(policy).to receive(:around_can).with(:update_activation_dates).and_call_original
      is_expected.to be_truthy
    end
  end
end
