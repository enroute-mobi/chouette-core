RSpec.describe StopAreaRoutingConstraint, type: :model do
  subject { create(:stop_area_routing_constraint, stop_area_provider: first_workbench.default_stop_area_provider) }

  it 'should validate that both stops are in the same referential and different' do
    stop_1 = create :stop_area, stop_area_provider: subject.stop_area_provider
    stop_2 = create :stop_area, stop_area_provider: subject.stop_area_provider
    sarc = StopAreaRoutingConstraint.new from: stop_1, to: stop_2, stop_area_provider: subject.stop_area_provider
    expect(sarc).to be_valid

    stop_2.stop_area_referential = create(:stop_area_referential)
    expect(sarc).to_not be_valid

    sarc = StopAreaRoutingConstraint.new from: stop_1, to: stop_1, stop_area_provider: subject.stop_area_provider
    expect(sarc).to_not be_valid
  end

  describe 'checksum' do
    it_behaves_like 'checksum support'
  end

  describe '#with_stop' do
    let!(:constraint){ create :stop_area_routing_constraint }
    let!(:other_constraint){ create :stop_area_routing_constraint }
    let!(:common_constraint){ create :stop_area_routing_constraint, from_stop_area: constraint.to }

    it 'should filter StopAreaRoutingConstraints' do
      expect(StopAreaRoutingConstraint.with_stop(constraint.from)).to match_array [constraint]
      expect(StopAreaRoutingConstraint.with_stop(constraint.to)).to match_array [constraint, common_constraint]
    end
  end
end
