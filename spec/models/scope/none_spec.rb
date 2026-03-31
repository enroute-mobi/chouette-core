# frozen_string_literal: true

RSpec.describe Scope::None do
  subject(:scope) { described_class.new }

  describe '#scopes?' do
    subject { scope.scopes?(collection_name) }

    context 'with a simple const name' do
      let(:collection_name) { :contracts }

      it { is_expected.to be(true) }
    end

    context 'with a Chouette const name' do
      let(:collection_name) { :lines }

      it { is_expected.to be(true) }
    end

    context 'with garbage' do
      let(:collection_name) { :dummy_dummies }

      it { is_expected.to be(false) }
    end

    context 'with a const name that is not an active record' do
      let(:collection_name) { :scopes }

      it { is_expected.to be(false) }
    end
  end

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: nil) }

    context 'with a simple const name' do
      let(:collection_name) { :contracts }

      it { is_expected.to be_empty }

      it 'returns a relation' do
        is_expected.to have_attributes(klass: Contract)
      end
    end

    context 'with a Chouette const name' do
      let(:collection_name) { :lines }

      it { is_expected.to be_empty }

      it 'returns a relation' do
        is_expected.to have_attributes(klass: Chouette::Line)
      end
    end
  end
end
