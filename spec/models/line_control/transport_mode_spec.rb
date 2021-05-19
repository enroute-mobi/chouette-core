
RSpec.describe LineControl::TransportMode, :type => :model do
  let(:referential){ create :workbench_referential }
  let(:workgroup){ referential.workgroup }
  let(:line){ create :line, line_referential: referential.line_referential}

  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check,
      iev_enabled_check: false,
      compliance_control_name: "LineControl::TransportMode",
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before(:each) do
    workgroup.transport_modes = {
      coach: [
        :undefined,
        :shuttleCoach
      ]
    }
    workgroup.save
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
  end

  context "when the line transport mode matches its workgroup configured ones" do
    before do
      line.transport_mode = "coach"
      line.transport_submode = "shuttleCoach"
      line.save
    end

    it "should find no error" do
      expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
      resource = ComplianceCheckResource.where(reference: line.objectid).last
      expect(resource.status).to eq "OK"
      expect(resource.compliance_check_messages.size).to eq 0
      expect(resource.metrics["error_count"]).to eq "0"
      expect(resource.metrics["ok_count"]).to eq "1"
    end
  end

  context "when the line transport mode doesn't match its workgroup configured ones" do
    before do
      line.transport_mode = "rail"
      line.transport_submode = "railShuttle"
      # line.save
    end

    it "should find an error" do
      expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
      resource = ComplianceCheckResource.where(reference: line.objectid).last
      expect(resource.status).to eq "ERROR"
      expect(resource.compliance_check_messages.size).to eq 1
      expect(resource.compliance_check_messages.last.message_key).to eq "3_line_4"
      expect(resource.compliance_check_messages.last.status).to eq "ERROR"
      expect(resource.compliance_check_messages.last.message_attributes['line_name']).to eq line.published_name
      expect(resource.metrics["error_count"]).to eq "1"
      expect(resource.metrics["ok_count"]).to eq "0"
    end
  end
end
