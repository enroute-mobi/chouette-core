# frozen_string_literal: true

RSpec.describe Scope::Line::Enabled do
  subject(:scope) { described_class.new }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    context 'with :lines' do
      let(:collection_name) { :lines }
      let(:current_collection) { Chouette::Line.all }

      let(:context) do
        Chouette.create do
          line :normal
          line :deactivated, deactivated: true
          line :active_from_yesterday, active_from: Date.yesterday
          line :active_from_tomorrow, active_from: Date.tomorrow
          line :active_until_yesterday, active_until: Date.yesterday
          line :active_until_tomorrow, active_until: Date.tomorrow
        end
      end

      it 'does not include disabled lines' do
        is_expected.to match_array(%i[normal active_from_yesterday active_until_tomorrow].map { |i| context.line(i) })
      end
    end
  end
end
