RSpec.describe ComplianceControl, type: :model do

  context 'standard validation' do

    let(:compliance_control) { build_stubbed :compliance_control }

    it { should belong_to :compliance_control_set }
    it { should belong_to :compliance_control_block }


    it { should validate_presence_of :criticity }
    it 'should validate_presence_of :name' do
      expect( build :compliance_control, name: '' ).to_not be_valid
    end
    it { should validate_presence_of :code }
    it { should validate_presence_of :origin_code }

  end

  context 'validates that direct and indirect (via control_block) control_set are not different instances' do

    it 'not attached to control_block -> valid' do
      compliance_control = create :compliance_control, compliance_control_block_id: nil
      expect(compliance_control).to be_valid
    end

    it 'attached to a control_block belonging to the same control_set -> valid' do
      compliance_control_block = create :compliance_control_block
      compliance_control = create :compliance_control,
        compliance_control_block_id: compliance_control_block.id,
        compliance_control_set_id: compliance_control_block.compliance_control_set.id # DO NOT change the last . to _
                                                                                      # We need to be sure that is is not nil
      expect(compliance_control).to be_valid
    end

    it 'attached to a control_block **not** belonging to the same control_set -> invalid' do
      compliance_control_block = create :compliance_control_block
      compliance_control = build :compliance_control,
        compliance_control_block_id: compliance_control_block.id,
        compliance_control_set_id: create( :compliance_control_set ).id
      expect(compliance_control).to_not be_valid

      direct_name      = compliance_control.compliance_control_set.name
      indirect_name    = compliance_control_block.compliance_control_set.name
      expected_message = "Le contrôle ne peut pas être associé à un jeu de contrôle (id: #{direct_name}) différent de celui de son groupe (id: #{indirect_name})"

      selected_error_message =
        compliance_control
          .errors
          .messages[:coherent_control_set]
          .first
      expect( selected_error_message ).to eq(expected_message)
    end
  end
end
