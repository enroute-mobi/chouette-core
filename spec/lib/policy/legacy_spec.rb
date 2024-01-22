# frozen_string_literal: true

RSpec.describe Policy::Legacy do
  subject(:policy) { Policy::Legacy.new(pundit_context, resource) }

  let(:pundit_context) { UserContext.new(double) }
  let(:resource) { double }

  describe '#pundit_policy_class' do
    context 'without argument' do
      subject { policy.pundit_policy_class }

      context 'when resource is an Organisation instance' do
        let(:resource) { Organisation.new }
        it { is_expected.to eq(OrganisationPolicy) }
      end

      context 'when resource is an User instance' do
        let(:resource) { User.new }
        it { is_expected.to eq(UserPolicy) }
      end
    end

    context 'with a resource class argument' do
      subject { policy.pundit_policy_class(resource_class) }

      context 'when the given resource class is User' do
        let(:resource_class) { User.new }
        it { is_expected.to eq(UserPolicy) }
      end
    end
  end

  describe 'with a User resource' do
    let(:resource) { User.new }

    describe '#edit?' do
      subject { policy.edit? }

      before { expect_any_instance_of(UserPolicy).to receive(:edit?).and_return(true) }

      it { is_expected.to be_truthy }
    end
  end

  describe 'with a Organisation resource' do
    let(:resource) { Organisation.new }

    describe '#create?(User)' do
      subject { policy.create?(User) }

      before { expect_any_instance_of(UserPolicy).to receive(:create?).and_return(true) }

      it { is_expected.to be_truthy }
    end
  end
end
