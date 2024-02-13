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

  describe '#policy_class_name' do
    subject { authorizer.policy_class_name(resource) }

    context 'for User resource' do
      let(:resource) { User.new }

      it { is_expected.to eq('Policy::User') }
    end

    context 'for Chouette::StopArea resource' do
      let(:resource) { Chouette::StopArea.new }

      it { is_expected.to eq('Policy::StopArea') }
    end
  end

  describe '#policy_class' do
    subject { authorizer.policy_class(resource) }

    context 'for User resource' do
      let(:resource) { User.new }

      it { is_expected.to eq(Policy::User) }
    end
  end

  describe '#policy' do
    subject { authorizer.policy(resource) }

    context 'by default' do
      let(:resource) { double }
      before { allow(authorizer).to receive(:policy_class).and_return(Policy::User) }

      it { is_expected.to have_attributes(context: authorizer.context) }
    end

    context 'for User resource' do
      let(:resource) { User.new }

      it { is_expected.to be_instance_of(Policy::User) }
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

RSpec.describe Policy::Authorizer::Legacy do
  subject(:authorizer) { described_class.new(controller) }
  let(:controller) { double }

  describe '#pundit_user_context' do
    subject { authorizer.pundit_user_context }

    context 'when Controller has a current_user' do
      let(:current_user) { double('current user provided by Controller') }
      before { allow(controller).to receive(:current_user).and_return(current_user) }

      it { is_expected.to have_attributes(user: current_user) }
    end

    context 'when Controller has a current_referential' do
      let(:current_referential) { double('current referential provided by Controller') }
      before { allow(controller).to receive(:current_referential).and_return(current_referential) }

      it { is_expected.to have_attributes(context: a_hash_including(referential: current_referential)) }
    end

    context 'when Controller has a current_workbench' do
      let(:current_workbench) { double('current workbench provided by Controller') }
      before { allow(controller).to receive(:current_workbench).and_return(current_workbench) }

      it { is_expected.to have_attributes(context: a_hash_including(workbench: current_workbench)) }
    end

    context 'when Controller has a current_workgroup' do
      let(:current_workgroup) { double('current workgroup provided by Controller') }
      before { allow(controller).to receive(:current_workgroup).and_return(current_workgroup) }

      it { is_expected.to have_attributes(context: a_hash_including(workgroup: current_workgroup)) }
    end
  end

  describe '#current_user' do
    subject { authorizer.current_user }
    let(:current_user) { double('current user provided by Controller') }

    before { allow(controller).to receive(:current_user).and_return(current_user) }

    it { is_expected.to eq(current_user) }
  end

  describe '#current_referential' do
    subject { authorizer.current_referential }
    let(:current_referential) { double('current referential provided by Controller') }

    before { allow(controller).to receive(:current_referential).and_return(current_referential) }

    it { is_expected.to eq(current_referential) }
  end

  describe '#current_workbench' do
    subject { authorizer.current_workbench }
    let(:current_workbench) { double('current workbench provided by Controller') }

    before { allow(controller).to receive(:current_workbench).and_return(current_workbench) }

    it { is_expected.to eq(current_workbench) }
  end

  describe '#current_workgroup' do
    subject { authorizer.current_workgroup }
    let(:current_workgroup) { double('current workgroup provided by Controller') }

    before { allow(controller).to receive(:current_workgroup).and_return(current_workgroup) }

    it { is_expected.to eq(current_workgroup) }
  end

  describe '#policy' do
    subject { authorizer.policy(resource) }
    let(:resource) { double('given resource') }

    it { is_expected.to have_attributes(resource: resource) }
    it { is_expected.to have_attributes(pundit_context: authorizer.pundit_user_context) }
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
