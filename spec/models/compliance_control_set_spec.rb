require 'rails_helper'

RSpec.describe ComplianceControlSet, type: :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:compliance_control_set)).to be_valid
  end

  it { should belong_to :organisation }
  it { should have_many(:compliance_controls).dependent(:destroy) }
  it { should have_many(:compliance_control_blocks).dependent(:destroy) }

  it { should validate_presence_of :name }

  context 'import/export' do
    let!(:control_set){ create :compliance_control_set }
    let!(:control_block){ create :compliance_control_block, compliance_control_set: control_set }
    let!(:control_inside_block){ create :vehicle_journey_control_wating_time, compliance_control_set: control_set, compliance_control_block: control_block }
    let!(:control_outside_block){ create :routing_constraint_zone_control_unactivated_stop_point, compliance_control_set: control_set }
    let(:export){ control_set.export }

    describe '#export' do
      it 'should export valid data' do
        expect(export[:compliance_controls]).to match_array([control_outside_block.export])
        expect(export[:compliance_control_blocks].size).to eq 1
        expect(export[:compliance_control_blocks].last[:compliance_controls]).to match_array([control_inside_block.export])
      end
    end

    describe '#import' do
      it 'should import valid data' do
        result = ComplianceControlSet.create name: 'test import', organisation: create(:organisation)
        result.import export

        expect(result.compliance_controls.count).to eq 2
        expect(result.compliance_controls.where(compliance_control_block_id: nil).last.export).to eq control_outside_block.export
        expect(result.compliance_control_blocks.count).to eq 1
        expect(result.compliance_control_blocks.last.export).to eq control_block.export
        expect(result.compliance_control_blocks.last.compliance_controls.last.export).to eq control_inside_block.export
      end

      it 'should fail with invalid data' do
        export_faulty = export.dup
        export_faulty[:compliance_controls] << export_faulty[:compliance_controls].last

        result = ComplianceControlSet.create name: 'test import', organisation: create(:organisation)

        controls_count = ComplianceControl.count
        control_blocks_count = ComplianceControlBlock.count
        expect{result.import(export_faulty)}.to raise_error
        expect(ComplianceControl.count).to eq controls_count
        expect(ComplianceControlBlock.count).to eq control_blocks_count
      end
    end
  end
end
