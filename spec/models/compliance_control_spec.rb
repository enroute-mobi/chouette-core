RSpec.describe ComplianceControl, type: :model do

  context 'dynamic attributes' do
    let(:compliance_control1) { build_stubbed :compliance_control }
    let(:compliance_control2) { build_stubbed :compliance_control, type: 'VehicleJouneyControl::TimeTable' }

    it 'should always return a array' do
       expect(compliance_control1.class.dynamic_attributes).to be_kind_of Array
       expect(compliance_control2.class.dynamic_attributes).to be_kind_of Array
    end
  end

  context '#available_for_organisation?' do
    context "without required_features" do
      let(:control) { Class.new(ComplianceControl) }
      let(:organisation) { build_stubbed :organisation, features: %w() }
      it "should be true" do
        expect(control.available_for_organisation?(organisation)).to be_truthy
      end
    end

    context "with one required feature" do
      let(:control) {
        control = Class.new(ComplianceControl)
        control.required_features :foo
        control
      }
      context "when the organisation does not have the feature" do
        let(:organisation) { build_stubbed :organisation, features: %w() }
        it "should be false" do
          expect(control.available_for_organisation?(organisation)).to be_falsy
        end
      end
      context "when the organisation has the feature" do
        let(:organisation) { build_stubbed :organisation, features: %w(foo bar) }
        it "should be true" do
          expect(control.available_for_organisation?(organisation)).to be_truthy
        end
      end
    end

    context "with two required feature" do
      let(:control) {
        control = Class.new(ComplianceControl)
        control.required_features :foo, :bar
        control
      }
      context "when the organisation does not have any feature" do
        let(:organisation) { build_stubbed :organisation, features: %w() }
        it "should be false" do
          expect(control.available_for_organisation?(organisation)).to be_falsy
        end
      end
      context "when the organisation has one of the features" do
        let(:organisation) { build_stubbed :organisation, features: %w(foo) }
        it "should be false" do
          expect(control.available_for_organisation?(organisation)).to be_falsy
        end
      end

      context "when the organisation has both features" do
        let(:organisation) { build_stubbed :organisation, features: %w(bar foo) }
        it "should be true" do
          expect(control.available_for_organisation?(organisation)).to be_truthy
        end
      end
    end

    context "without constraint" do
      let(:control) {
        control = Class.new(ComplianceControl)
        control
      }

      it "should be true" do
        expect(control.available_for_organisation?(organisation)).to be_truthy
      end

      context "when not available for the organisation entirely" do
        before do
          expect(control).to receive(:available_for_organisation?).with(organisation).and_return(false)
        end
        it "should be false" do
          expect(control.available_for_organisation?(organisation)).to be_falsy
        end
      end
    end

    context "with a matched constraint" do
      let(:control) {
        control = Class.new(ComplianceControl)
        control.only_if ->(o){ true }
        control
      }

      it "should be true" do
        expect(control.available_for_organisation?(organisation)).to be_truthy
      end
    end

    context "with a not matched constraint" do
      let(:control) {
        control = Class.new(ComplianceControl)
        control.only_if ->(o){ false }
        control
      }

      it "should be false" do
        expect(control.available_for_organisation?(organisation)).to be_falsy
      end
    end
  end



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
