
RSpec.describe VehicleJourneyControl::PublishedJourneyName, :type => :model do
  let(:workgroup){ referential.workgroup }
  let(:line){ create :line, line_referential: workgroup.line_referential }
  let(:route){ create :route, line: line }
  let(:journey_pattern){ create :journey_pattern, route: route }

  let(:company) { create :company, line_referential: workgroup.line_referential }
  let(:vj) { create :vehicle_journey_empty, journey_pattern: journey_pattern, route: route, company: company, published_journey_name: "4"}

  let(:criticity){ "warning" }
  let(:control_attributes) {
    {
      minimum: "1",
      maximum: "10",
      company_id: company.id.to_s
    }
  }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "VehicleJourneyControl::PublishedJourneyName",
      control_attributes: control_attributes,
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before(:each) do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
    referential.switch do
      vj
    end
  end

  context "when all the vehicle jorneys with company_id have a published journey name between the range" do
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when at least one vehicle jorneys with company_id have a published journey name outside of the the range" do
    before do
      referential.switch do
        Chouette::VehicleJourney.update_all(published_journey_name: "15")
      end
    end

     context "when the criticity is warning" do
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
      let(:criticity){ "error" }
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
