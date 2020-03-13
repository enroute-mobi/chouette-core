
RSpec.describe StopAreaControl::TimeZone, :type => :model do
  let(:line_referential){ referential.line_referential }
  let(:stop_area_referential){ referential.stop_area_referential }
  let!(:line){ create :line, line_referential: line_referential }

  let(:control_attributes) { {} }
  let(:criticity){ "warning" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential }
  let(:compliance_check_block) { nil }
  let(:compliance_check){
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: "StopAreaControl::TimeZone",
      control_attributes: control_attributes,
      compliance_check_set: compliance_check_set,
      criticity: criticity,
      compliance_check_block: compliance_check_block
  }

  before(:each) do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
    referential.switch
  end

  context "when all stop_areas have a timezone set" do
    before do
      route = create :route, line: line
      route.stop_areas.update_all time_zone: 'Europe/Paris', stop_area_referential_id: stop_area_referential.id
    end

    it "should pass" do
      expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when one stop area is missing a TZ" do
    context "without border" do
      before do
        route = create :route, line: line
        route.stop_areas.update_all time_zone: 'Europe/Paris', stop_area_referential_id: stop_area_referential.id
        route.stop_areas.last.update time_zone: nil
      end

      it "should not pass" do
        expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
        resource = ComplianceCheckResource.last
        expect(resource.status).to eq "WARNING"
      end
    end
  end

  context 'with a compliance_check_block' do
    let(:compliance_check_block) { create :compliance_check_block, transport_mode: :bus, compliance_check_set: compliance_check_set }

    context "when all stop_areas have a timezone set" do
      before do
        route = create :route, line: line
        route.stop_areas.update_all time_zone: 'Europe/Paris', stop_area_referential_id: stop_area_referential.id
      end

      it "should pass" do
        expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
        resource = ComplianceCheckResource.last
        expect(resource.status).to eq "OK"
      end
    end

    context "when one stop area is missing a TZ" do
      context "without border" do
        before do
          route = create :route, line: line
          route.stop_areas.update_all time_zone: 'Europe/Paris', stop_area_referential_id: stop_area_referential.id
          route.stop_areas.last.update time_zone: nil
        end

        it "should not pass" do
          expect{compliance_check.process}.to change{ ComplianceCheckResource.count }.by 1
          resource = ComplianceCheckResource.last
          expect(resource.status).to eq "WARNING"
        end
      end
    end
  end
end
