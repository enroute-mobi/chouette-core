
RSpec.describe VehicleJourneyControl::PurchaseWindowDates, :type => :model do
  let(:workgroup){ referential.workgroup }
  let(:line){ create :line, line_referential: workgroup.line_referential }
  let(:route){ create :route, line: line }
  let(:journey_pattern){ create :journey_pattern, route: route }

  let(:time_table) {create :time_table, dates: [], periods: [ create(:time_table_period, period_start: Date.today, period_end: Date.today + 10) ]}
  let(:empty_time_table) {create :time_table, dates_count: 0, periods_count: 0}
  let(:purchase_window) { create :purchase_window, date_ranges: [(time_table.start_date+1)...(time_table.end_date-1)]}

  let(:vj) { create :vehicle_journey_empty, journey_pattern: journey_pattern, route: route, time_tables: [time_table], purchase_windows: [purchase_window]}
  let(:vj2) { create :vehicle_journey_empty, journey_pattern: journey_pattern, route: route, time_tables: [empty_time_table], purchase_windows: [purchase_window]}

  let(:criticity){ "warning" }
  let(:control_attributes) {
    {}
  }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "VehicleJourneyControl::PurchaseWindowDates",
      control_attributes: control_attributes,
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before(:each) do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
    referential.switch do
      time_table
      empty_time_table
      purchase_window
      vj && vj2
    end
  end

  context "when all the vehicle journeys with company_id have a published journey name between the range" do
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when an error is raised" do
    it "should set the status to ERROR" do
      expect(VehicleJourneyControl::PurchaseWindowDates).to receive(:compliance_test).and_raise
      expect{compliance_check.process}.to raise_error RuntimeError
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "ERROR"
    end
  end

  context "when at least one vehicle jorneys with company_id have a published journey name outside of the the range" do
    before(:each) do
      referential.switch do
        Chouette::PurchaseWindow.update_all(date_ranges: [(time_table.start_date)..(time_table.end_date+1)])
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
