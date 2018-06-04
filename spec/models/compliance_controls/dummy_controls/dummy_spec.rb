require 'rails_helper'

RSpec.describe DummyControl::Dummy, :type => :model do
  let!(:line_referential){ create :line_referential }
  let!(:referential){ create :referential, line_referential: line_referential }
  let!(:line){ create :line, line_referential: line_referential }
  let(:control_attributes){
    {
      "status" => status
    }
  }
  let(:status){ "OK" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){ create :compliance_check, iev_enabled_check: false, compliance_control_name: "DummyControl::Dummy", control_attributes: control_attributes, compliance_check_set: compliance_check_set}

  it "should set the status according to its params" do
    expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
    resource = ComplianceCheckResource.last
    expect(resource.status).to eq "OK"
  end

  context "when the status has already been set" do
    {
      ["IGNORED", "IGNORED"] => "IGNORED",
      ["IGNORED", "WARNING"] => "WARNING",
      ["IGNORED", "OK"]      => "OK",
      ["IGNORED", "ERROR"]   => "ERROR",
      ["OK", "IGNORED"] => "OK",
      ["OK", "WARNING"] => "WARNING",
      ["OK", "OK"]      => "OK",
      ["OK", "ERROR"]   => "ERROR",
      ["WARNING", "IGNORED"] => "WARNING",
      ["WARNING", "WARNING"] => "WARNING",
      ["WARNING", "OK"]      => "WARNING",
      ["WARNING", "ERROR"]   => "ERROR",
      ["ERROR", "IGNORED"] => "ERROR",
      ["ERROR", "WARNING"] => "ERROR",
      ["ERROR", "OK"]      => "ERROR",
      ["ERROR", "ERROR"]   => "ERROR",
    }.each do |statuses, expected|
      context "with a previous status being #{statuses.first}, and the dummy set to #{statuses.last}" do
        let(:previous_status){ statuses.first }
        let(:status){ statuses.last }
        before(:each) do
          compliance_check_set.compliance_check_resources.create do |res|
            res.reference = line.objectid
            res.resource_type = "line"
            res.name = line.name
            res.status = previous_status
          end
        end
        it "should set the status according to its params and the previous status" do
          expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 0
          resource = ComplianceCheckResource.last
          expect(resource.status).to eq expected
        end
      end
    end
  end
end
