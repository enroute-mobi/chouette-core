require 'rails_helper'

RSpec.describe JourneyPatternControl::MinimumLength, :type => :model do
  let!(:line){ create :line }
  let!(:ref){ create :workbench_referential, metadatas: [create(:referential_metadata, lines: [line])] }
  let!(:route) {create :route, line: line}
  let!(:jp) { create :journey_pattern, route: route}
  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check,
      iev_enabled_check: false,
      compliance_control_name: "JourneyPatternControl::MinimumLength",
      control_attributes: {},
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  context "when the journey pattern have all 2 or more stop points" do
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when at least one journey pattern have less than 2 stop points" do
    before do
      sp_id = route.stop_points.first.id
      jp.update(stop_point_ids: [sp_id], departure_stop_point_id: sp_id, arrival_stop_point_id: sp_id )
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
