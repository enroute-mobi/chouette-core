require 'rails_helper'

RSpec.describe ComplianceControlSet, type: :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:compliance_control_set)).to be_valid
  end

  it { should belong_to :organisation }
  it { should have_many(:compliance_controls).dependent(:destroy) }
  it { should have_many(:compliance_control_blocks).dependent(:destroy) }

  it { should validate_presence_of :name }

  describe '#export' do
    let!(:control_set){ create :compliance_control_set }
    let!(:control_block){ create :compliance_control_block, compliance_control_set: control_set }
    let!(:control_inside_block){ create :vehicle_journey_control_wating_time, compliance_control_set: control_set, compliance_control_block: control_block }
    let!(:control_outside_block){ create :routing_constraint_zone_control_unactivated_stop_point, compliance_control_set: control_set }

    it 'should export valid data' do
      export = control_set.export
      expect(export[:compliance_control_checks]).to match_array([control_outside_block.export])
      expect(export[:compliance_control_blocks].size).to eq 1
      expect(export[:compliance_control_blocks].last[:compliance_control_checks]).to match_array([control_inside_block.export])
    end
  end
end
