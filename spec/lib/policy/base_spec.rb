# frozen_string_literal: true

RSpec.describe Policy::Base do
  subject(:policy) { Policy::Base.new(resource) }

  let(:resource) { double }

  describe '#can?' do
    subject { policy.can?(:dummy) }

    it { is_expected.to be_falsy }
  end

  describe '#something?' do
    subject { policy.something? }

    it 'invokes can? method with :something action' do
      expect(policy).to receive(:can?).with(:something).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#create?(resource_class)' do
    subject { policy.create?(resource_class) }
    let(:resource_class) { User }

    it 'invokes can? method with :create and given resource class action' do
      expect(policy).to receive(:can?).with(:create, resource_class).and_return(true)
      is_expected.to be_truthy
    end
  end
end
