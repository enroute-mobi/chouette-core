# frozen_string_literal: true

RSpec.describe Scope::Workbench do
  subject(:scope) { Scope::Workbench.new(workbench) }

  let(:context) { Chouette.create { workbench } }
  let(:workbench) { context.workbench }

  %i[
    routes stop_points journey_patterns journey_pattern_stop_points
    vehicle_journeys time_tables time_table_periods time_table_dates service_counts
  ].each do |empty_method|
    describe "##{empty_method}" do
      subject { scope.send(empty_method) }
      it { is_expected.to be_empty }
    end
  end
end

RSpec.describe Scope::Owned do
  subject(:scope) { Scope::Owned.new(parent_scope, workbench) }

  let(:context) { Chouette.create { workbench } }
  let(:workbench) { context.workbench }

  let(:parent_scope) { Scope::Workbench.new(workbench) }

  %i[
    routes stop_points journey_patterns journey_pattern_stop_points
    vehicle_journeys time_tables time_table_periods time_table_dates service_counts
  ].each do |collection|
    describe "##{collection}" do
      subject { scope.send collection }

      let(:parent_result) { double('Parent Scope result') }

      it 'invokes the parent scope collection' do
        expect(parent_scope).to receive(collection).and_return(parent_result)
        is_expected.to eq(parent_result)
      end
    end
  end
end
