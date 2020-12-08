RSpec.describe CustomFieldControl::Presence, :type => :model do
  let!(:workgroup) { create :workgroup }
  let!(:line_referential){ workgroup.line_referential }
  let!(:referential){ create :referential, line_referential: line_referential }
  let!(:company) do
    create :company, line_referential: line_referential, custom_field_values: { public_name: company_name }
  end

  let!(:custom_field_public_name) { create :custom_field, field_type: :string, code: :public_name, name: "Name", workgroup: workgroup, resource_type: "Company" }

  let!(:line) { create :line, company: company, line_referential: line_referential }

  let(:control_attributes){
    {
      custom_field_code: :public_name
    }
  }
  let(:company_name){ "A NAME" }
  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "CustomFieldControl::Presence",
      control_attributes: control_attributes,
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  context "when the company has a name" do
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when the company has lines outside of the referential" do
    before do
      create :line, company_id: company.id
    end
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when the company has no name" do
    let(:company_name){ "" }

    context "when the criticity is warning" do
      let(:criticity){ "warning" }

      it "should set the status according to its params" do
        expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
        resource = ComplianceCheckResource.last
        expect(resource.status).to eq "WARNING"
      end

      it "should create a message" do
        expect{compliance_check.process}.to change{ComplianceCheckMessage.count}.by 1
        message = ComplianceCheckMessage.last
        expect(message.status).to eq "WARNING"
        expect(message.compliance_check_set).to eq compliance_check_set
        expect(message.compliance_check).to eq compliance_check
        expect(message.compliance_check_resource).to eq ComplianceCheckResource.last
      end
    end

    context "when the criticity is error" do
      it "should set the status according to its params" do
        expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
        resource = ComplianceCheckResource.last
        expect(resource.status).to eq "ERROR"
      end

      it "should create a message" do
        expect{compliance_check.process}.to change{ComplianceCheckMessage.count}.by 1
        message = ComplianceCheckMessage.last
        expect(message.status).to eq "ERROR"
        expect(message.compliance_check_set).to eq compliance_check_set
        expect(message.compliance_check).to eq compliance_check
        expect(message.compliance_check_resource).to eq ComplianceCheckResource.last
      end
    end
  end
end
