
RSpec.describe RouteControl::StopAreaTypes, :type => :model do
  let(:line_referential){ referential.line_referential }
  let!(:line){ create :line, line_referential: line_referential }
  let!(:route) {create :route, line: line}
  let!(:route2) {create :route, line: line}
  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "RouteControl::StopAreaTypes",
      control_attributes: {},
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before(:each) do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
  end

  # By default, a stop_area_referential has only zdl as permitted type, and all route stop_points are zdl in the Factory
  context "when the routes only uses valid StopAreas" do
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when at least one route uses an invalid stop" do
    before do
      lda = route2.stop_areas.first
      lda.area_type = "lda"
      lda.save
    end

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
