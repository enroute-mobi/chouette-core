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
