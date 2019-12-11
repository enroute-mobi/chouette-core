require 'rails_helper'

RSpec.describe RouteControl::ValidStopAreas, :type => :model do
  let(:line_referential){ referential.line_referential }
  let!(:line){ create :line, line_referential: line_referential }
  let!(:route) {create :route, line: line}
  let!(:route2) {create :route, line: line}
  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "RouteControl::ValidStopAreas",
      control_attributes: {},
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before(:each) do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
  end

  context "when the routes only uses valid StopAreas" do
    before(:each) do
      allow(referential.workbench).to receive(:stop_areas).and_return Chouette::StopArea.all
    end
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when at least one route uses an invalid stop" do
    before do
      allow(referential.workbench).to receive(:stop_areas).and_return Chouette::StopArea.where.not(id: [route.stop_areas.last, route2.stop_areas.last])
    end

    it "should set the status according to its params" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "ERROR"
    end

    it "should create a message" do
      expect{compliance_check.process}.to change{ComplianceCheckMessage.count}.by 2
      message = ComplianceCheckMessage.last
      expect(message.status).to eq "ERROR"
      expect(message.compliance_check_set).to eq compliance_check_set
      expect(message.compliance_check).to eq compliance_check
      expect(message.compliance_check_resource).to eq ComplianceCheckResource.last
    end
  end
end
