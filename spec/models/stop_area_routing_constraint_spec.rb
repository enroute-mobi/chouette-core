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

  describe '#vehicle_journeys' do
    let(:ignoring){ create :vehicle_journey }
    let(:deleted){ create :vehicle_journey }
    let(:not_ignoring){ create :vehicle_journey }
    let(:other_referential){ create :referential }
    let(:in_other_referential){ other_referential.switch { create :vehicle_journey, ignored_stop_area_routing_constraint_ids: [subject.id] } }
    it 'should find the vehicle_journeys ignoring the subject' do
      @found = []
      in_other_referential.run_callbacks(:commit)
      not_ignoring.run_callbacks(:commit)
      ignoring.run_callbacks(:commit)
      ignoring.update ignored_stop_area_routing_constraint_ids: [subject.id]
      ignoring.run_callbacks(:commit)
      deleted.run_callbacks(:commit)
      deleted.update ignored_stop_area_routing_constraint_ids: [subject.id]
      deleted.run_callbacks(:commit)
      deleted.destroy
      not_ignoring.update ignored_stop_area_routing_constraint_ids: [subject.id]
      not_ignoring.run_callbacks(:commit)
      not_ignoring.update ignored_stop_area_routing_constraint_ids: []
      not_ignoring.run_callbacks(:commit)

      other_referential.switch
      subject.vehicle_journeys.each do |found|
        @found << found
      end
      expect(@found).to match_array [ignoring, in_other_referential]
      expect(subject.vehicle_journeys.all).to match_array [ignoring, in_other_referential]
    end
  end
end
