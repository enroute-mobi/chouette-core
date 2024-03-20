# frozen_string_literal: true

RSpec.describe Policy::Authorizer::Controller do
  subject(:authorizer) { described_class.new(controller) }

  let(:controller) { double policy_context_class: Policy::Context::Base }

  describe '.authorizer_class' do
    subject { described_class.authorizer_class(ApplicationController.new) }

    it { is_expected.to eq(Policy::Authorizer::Controller) }

    context 'when Policy::Authorizer::Controller.default_class is e.g. PermitAll' do
      before { allow(Policy::Authorizer::Controller).to receive(:default_class).and_return(default_class) }
      let(:default_class) { Policy::Authorizer::PermitAll }

      it { is_expected.to eq(default_class) }
    end

    context 'when an exception is defined e.g. PermitAll for ApplicationController' do
      before { Policy::Authorizer::Controller.for(ApplicationController, exception) }
      let(:exception) { Policy::Authorizer::PermitAll }

      it { is_expected.to eq(exception) }

      after { Policy::Authorizer::Controller.exceptions.delete(ApplicationController) }
    end
  end

  describe '.policy_class_name' do
    subject { described_class.policy_class_name(resource_class) }

    context 'for User' do
      let(:resource_class) { User }

      it { is_expected.to eq('Policy::User') }
    end

    context 'for Chouette::StopArea' do
      let(:resource_class) { Chouette::StopArea }

      it { is_expected.to eq('Policy::StopArea') }
    end

    context 'for Control::List' do
      let(:resource_class) { Control::List }

      it { is_expected.to eq('Policy::Control::List') }
    end

    context 'for Import::Base resource' do
      let(:resource_class) { Import::Base }

      it { is_expected.to eq('Policy::Import') }
    end
  end

  describe '.policy_class' do
    subject { described_class.policy_class(resource_class) }

    context 'for User' do
      let(:resource_class) { User }

      it { is_expected.to eq(Policy::User) }
    end

    context 'for Dummy' do
      # rubocop:disable Style/SingleLineMethods,Rails/ApplicationRecord
      let(:resource_class) { Class.new(ActiveRecord::Base) { def self.name; 'Dummy'; end } }
      # rubocop:enable Style/SingleLineMethods,Rails/ApplicationRecord

      it { is_expected.to be_nil }
    end
  end

  describe '#policy' do
    subject { authorizer.policy(resource) }

    context 'by default' do
      let(:resource) { double }
      before { allow(described_class).to receive(:policy_class).and_return(Policy::User) }

      it { is_expected.to have_attributes(context: authorizer.context) }
    end

    context 'for User resource' do
      let(:resource) { User.new }

      it { is_expected.to be_instance_of(Policy::User) }

      context 'when decorated' do
        let(:resource) { super().decorate }

        it { is_expected.to be_instance_of(Policy::User) }
      end
    end

    context 'for nil' do
      let(:resource) { nil }

      it { is_expected.to eq(Policy::DenyAll.instance) }
    end
  end

  describe '#context' do
    subject { authorizer.context }

    it { is_expected.to be_instance_of(Policy::Context::Base) }

    context 'when controller has a user "dummy"' do
      let(:controller) { double policy_context_class: Policy::Context::User, current_user: 'dummy' }

      it { is_expected.to be_instance_of(Policy::Context::User) }
      it { is_expected.to have_attributes(user: 'dummy') }
    end
  end
end

RSpec.describe Policy::Authorizer::PermitAll do
  subject(:authorizer) { described_class.new }

  describe '#policy' do
    subject { authorizer.policy(resource) }
    let(:resource) { double('given resource') }

    it { is_expected.to have_attributes(resource: resource) }
    it { is_expected.to be_instance_of(Policy::PermitAll) }
  end
end
