# frozen_string_literal: true

RSpec.describe Policy::Context do
  describe Policy::Context::User do
    it { is_expected.to have_attribute(:user) }

    describe '.from' do
      subject { described_class.from provider }

      context 'when the given provider has a method user which returns "dummy"' do
        let(:provider) { double(user: 'dummy') }

        it { is_expected.to have_attributes(user: 'dummy') }
      end

      context 'when the given provider has a method current_user which returns "dummy"' do
        let(:provider) { double(current_user: 'dummy') }

        it { is_expected.to have_attributes(user: 'dummy') }
      end
    end
  end

  describe Policy::Context::Workgroup do
    it { is_expected.to have_attribute(:user) }
    it { is_expected.to have_attribute(:workgroup) }

    describe '.from' do
      subject { described_class.from provider }

      context 'when the given provider has a method workgroup which returns "dummy"' do
        let(:provider) { double(workgroup: 'dummy') }

        it { is_expected.to have_attributes(workgroup: 'dummy') }
      end

      context 'when the given provider has a method current_workgroup which returns "dummy"' do
        let(:provider) { double(current_workgroup: 'dummy') }

        it { is_expected.to have_attributes(workgroup: 'dummy') }
      end
    end
  end

  describe Policy::Context::Workbench do
    it { is_expected.to have_attribute(:user) }
    it { is_expected.to have_attribute(:workgroup) }
    it { is_expected.to have_attribute(:workbench) }

    describe '.from' do
      subject { described_class.from provider }

      context 'when the given provider has a method workbench which returns "dummy"' do
        let(:provider) { double(workbench: 'dummy') }

        it { is_expected.to have_attributes(workbench: 'dummy') }
      end

      context 'when the given provider has a method current_workbench which returns "dummy"' do
        let(:provider) { double(current_workbench: 'dummy') }

        it { is_expected.to have_attributes(workbench: 'dummy') }
      end
    end
  end

  describe Policy::Context::Referential do
    it { is_expected.to have_attribute(:user) }
    it { is_expected.to have_attribute(:workgroup) }
    it { is_expected.to have_attribute(:workbench) }
    it { is_expected.to have_attribute(:referential) }

    describe '.from' do
      subject { described_class.from provider }

      context 'when the given provider has a method referential which returns "dummy"' do
        let(:provider) { double(referential: 'dummy') }

        it { is_expected.to have_attributes(referential: 'dummy') }
      end

      context 'when the given provider has a method current_referential which returns "dummy"' do
        let(:provider) { double(current_referential: 'dummy') }

        it { is_expected.to have_attributes(referential: 'dummy') }
      end
    end
  end
end
