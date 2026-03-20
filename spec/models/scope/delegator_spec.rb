# frozen_string_literal: true

RSpec.describe Scope::Delegator do
  subject(:scope) { delegator_class.new(object) }

  let(:object) { double('object', something: :something) }

  let(:delegator_class) do
    Class.new(described_class) do
      collection :some_collection do
        object.something
      end
    end.tap do |klass|
      klass::SUPPORTED = %i[delegated_collection].freeze
    end
  end

  describe '#scopes?' do
    subject { scope.scopes?(collection_name) }

    context 'with a supported collection' do
      let(:collection_name) { :delegated_collection }

      it { is_expected.to be(true) }
    end

    context 'with a classic collection' do
      let(:collection_name) { :some_collection }

      it { is_expected.to be(true) }
    end

    context 'with garbage' do
      let(:collection_name) { :dummy }

      it { is_expected.to be(false) }
    end
  end

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: nil) }

    context 'with a supported collection' do
      let(:collection_name) { :delegated_collection }

      it 'delegates the call to object' do
        expect(object).to receive(:delegated_collection)
        subject
      end
    end

    context 'with a classic collection' do
      let(:collection_name) { :some_collection }

      it { is_expected.to eq(:something) }
    end
  end
end
