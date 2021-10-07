
RSpec.describe LineControl::Active, :type => :model do
  let(:referential){ create :workbench_referential }
  let(:workgroup){ referential.workgroup }
  let(:deactivated){ nil }
  let(:active_from){ nil }
  let(:active_until){ nil }
  let(:line){ create :line, line_referential: referential.line_referential, deactivated: deactivated, active_from: active_from, active_until: active_until}
  let(:route){ create :route, line: line }
  let(:journey_pattern){ create :journey_pattern, route: route }
  let(:vehicle_journey){ create :vehicle_journey, journey_pattern: journey_pattern, published_journey_name: '001' }

  let(:control_attributes){
    { duration: "5" }
  }
  let(:criticity){ "error" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "LineControl::Active",
      compliance_check_set: compliance_check_set,
      control_attributes: control_attributes,
      criticity: criticity
  }

  before(:each) do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
  end

  # Validations
  it { should validate_numericality_of(:duration) }

  context 'when the line is active' do
    it "should find no error" do
      expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
      resource = ComplianceCheckResource.where(reference: line.objectid).last
      expect(resource.status).to eq "OK"
      expect(resource.compliance_check_messages.size).to eq 0
      expect(resource.metrics["error_count"]).to eq "0"
      expect(resource.metrics["ok_count"]).to eq "1"
    end

    context 'with a journey' do
      before { referential.switch { vehicle_journey }}

      it "should find no error" do
        expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
        resource = ComplianceCheckResource.where(reference: line.objectid).last
        expect(resource.status).to eq "OK"
        expect(resource.compliance_check_messages.size).to eq 0
        expect(resource.metrics["error_count"]).to eq "0"
        expect(resource.metrics["ok_count"]).to eq "1"
      end

      context 'with a active_from in the future' do
        let(:active_from){ 1.day.from_now }

        it "should find an error" do
          expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
          resource = ComplianceCheckResource.where(reference: line.objectid).last
          expect(resource.status).to eq "ERROR"
          expect(resource.compliance_check_messages.size).to eq 1
          expect(resource.compliance_check_messages.last.status).to eq "ERROR"
          expect(resource.compliance_check_messages.last.message_attributes['line_name']).to eq line.published_name
          expect(resource.metrics["error_count"]).to eq "1"
          expect(resource.metrics["ok_count"]).to eq "0"
        end
      end

      context 'with a active_from in the past' do
        let(:active_from){ 1.day.ago }

        it "should find no error" do
          expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
          resource = ComplianceCheckResource.where(reference: line.objectid).last
          expect(resource.status).to eq "OK"
          expect(resource.compliance_check_messages.size).to eq 0
          expect(resource.metrics["error_count"]).to eq "0"
          expect(resource.metrics["ok_count"]).to eq "1"
        end
      end

      context 'with a active_until before the end of the period' do
        let(:active_until){ 1.day.from_now }

        it "should find an error" do
          expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
          resource = ComplianceCheckResource.where(reference: line.objectid).last
          expect(resource.status).to eq "ERROR"
          expect(resource.compliance_check_messages.size).to eq 1
          expect(resource.compliance_check_messages.last.status).to eq "ERROR"
          expect(resource.compliance_check_messages.last.message_attributes['line_name']).to eq line.published_name
          expect(resource.metrics["error_count"]).to eq "1"
          expect(resource.metrics["ok_count"]).to eq "0"
        end
      end

      context 'with a active_until after the end of the period' do
        let(:active_until){ 6.day.from_now }

        it "should find no error" do
          expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
          resource = ComplianceCheckResource.where(reference: line.objectid).last
          expect(resource.status).to eq "OK"
          expect(resource.compliance_check_messages.size).to eq 0
          expect(resource.metrics["error_count"]).to eq "0"
          expect(resource.metrics["ok_count"]).to eq "1"
        end
      end
    end
  end

  context 'when the line is inactive' do
    let(:deactivated){ true }
    it "should find no error" do
      expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
      resource = ComplianceCheckResource.where(reference: line.objectid).last
      expect(resource.status).to eq "OK"
      expect(resource.compliance_check_messages.size).to eq 0
      expect(resource.metrics["error_count"]).to eq "0"
      expect(resource.metrics["ok_count"]).to eq "1"
    end

    context 'with a journey' do
      before { referential.switch { vehicle_journey }}

      it "should find an error" do
        expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
        resource = ComplianceCheckResource.where(reference: line.objectid).last
        expect(resource.status).to eq "ERROR"
        expect(resource.compliance_check_messages.size).to eq 1
        expect(resource.compliance_check_messages.last.status).to eq "ERROR"
        expect(resource.compliance_check_messages.last.message_attributes['line_name']).to eq line.published_name
        expect(resource.metrics["error_count"]).to eq "1"
        expect(resource.metrics["ok_count"]).to eq "0"
      end
    end
  end
end
