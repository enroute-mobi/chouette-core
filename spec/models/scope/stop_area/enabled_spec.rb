# frozen_string_literal: true

RSpec.describe Scope::StopArea::Enabled do
  subject(:scope) { described_class.new }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    context 'with :stop_areas' do
      let(:collection_name) { :stop_areas }
      let(:current_collection) { Chouette::StopArea.all }

      let(:context) do
        Chouette.create do
          stop_area :normal
          stop_area :disabled, deleted_at: Time.zone.now
        end
      end

      it 'does not include disabled stop areas' do
        is_expected.to contain_exactly(context.stop_area(:normal))
      end
    end
  end
end
