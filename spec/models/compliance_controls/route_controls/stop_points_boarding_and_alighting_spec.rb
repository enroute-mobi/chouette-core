
RSpec.describe RouteControl::StopPointsBoardingAndAlighting, :type => :model do
  let(:line_referential){ referential.line_referential }
  let!(:line){ create :line, line_referential: line_referential }
  let!(:route) {create :route, line: line}
  let(:control_attributes){
    {}
  }

  let(:criticity){ "warning" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "RouteControl::StopPointsBoardingAndAlighting",
      control_attributes: control_attributes,
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before {
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
    stop_area = create :stop_area, kind: :non_commercial, area_type: :border
    route.stop_points.create stop_area: stop_area
    expect(referential.stop_points.non_commercial.count).to be > 0
    expect(referential.stop_points.commercial.count).to be > 0
  }

  context "when the stop points have all boarding & alighting set to forbidden" do
    before do
      referential.stop_points.non_commercial.update_all(for_boarding: "forbidden", for_alighting: "forbidden")
    end
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when at least one stop point have boarding or alighting set to normal" do
    before do
      referential.stop_points.non_commercial.last.update(for_boarding: "normal", for_alighting: "normal")
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
