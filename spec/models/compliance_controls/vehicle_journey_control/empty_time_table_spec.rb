require 'rails_helper'

RSpec.describe VehicleJourneyControl::EmptyTimeTable, :type => :model do
  let(:referential){ create :workbench_referential }
  let(:workgroup){ referential.workgroup }
  let(:line){ create :line, line_referential: referential.line_referential }
  let(:route){ create :route, line: line }
  let(:journey_pattern){ create :journey_pattern, route: route }
  let(:succeeding){ create :vehicle_journey, journey_pattern: journey_pattern, published_journey_name: '001' }
  let(:failing){ create :vehicle_journey, journey_pattern: journey_pattern, published_journey_name: '002' }
  let(:empty_tt){ create :time_table, :empty }
  let(:tt){ create :time_table }

  let(:control_attributes){
    {}
  }
  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "VehicleJourneyControl::EmptyTimeTable",
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before(:each) do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
    referential.switch do
      succeeding.time_tables << tt
      failing.time_tables << empty_tt
    end
  end

  it "should detect empty timetables" do
    expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
    resource = ComplianceCheckResource.where(reference: succeeding.route.line.objectid).last
    expect(resource.status).to eq "ERROR"
    expect(resource.compliance_check_messages.size).to eq 1
    expect(resource.compliance_check_messages.last.status).to eq "ERROR"
    expect(resource.compliance_check_messages.last.message_attributes['vj_name']).to eq failing.published_journey_name
    expect(resource.metrics["error_count"]).to eq "1"
    expect(resource.metrics["ok_count"]).to eq "1"
  end
end
