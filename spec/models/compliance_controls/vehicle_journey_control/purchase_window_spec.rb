require 'rails_helper'

RSpec.describe VehicleJourneyControl::PurchaseWindow, :type => :model do
  let(:referential){ create :workbench_referential }
  let(:workgroup){ referential.workgroup }
  let(:line){ create :line, line_referential: workgroup.line_referential }
  let(:route){ create :route, line: line }
  let(:journey_pattern){ create :journey_pattern, route: route }
  let(:succeeding){ create :vehicle_journey, journey_pattern: journey_pattern }
  let(:failing){ create :vehicle_journey, journey_pattern: journey_pattern }
  let(:failing_too){ create :vehicle_journey, journey_pattern: journey_pattern }
  let(:failing_too_too){ create :vehicle_journey }
  let(:purchase_window){ create :purchase_window, referential: referential }
  let(:control_attributes){
    {}
  }
  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check,
      iev_enabled_check: false,
      compliance_control_name: "VehicleJourneyControl::PurchaseWindow",
      control_attributes: control_attributes,
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before(:each) do
    referential.switch do
      failing
      failing_too
      failing_too_too
      succeeding.purchase_windows << purchase_window
    end
  end

  it "should detect missing purchase windows" do
    expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 2
    resource = ComplianceCheckResource.where(reference: succeeding.route.line.objectid).last
    expect(resource.status).to eq "ERROR"
    expect(resource.compliance_check_messages.size).to eq 2
    expect(resource.compliance_check_messages.last.status).to eq "ERROR"
    expect(resource.metrics["error_count"]).to eq "2"
    expect(resource.metrics["ok_count"]).to eq "1"
    resource = ComplianceCheckResource.where(reference: failing_too_too.line.objectid).last
    expect(resource.status).to eq "ERROR"
    expect(resource.compliance_check_messages.size).to eq 1
    expect(resource.compliance_check_messages.last.status).to eq "ERROR"
  end
end
