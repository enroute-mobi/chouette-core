require 'rails_helper'

RSpec.describe RouteControl::BorderCount, :type => :model do
  let!(:line){ create :line }
  let!(:ref){ create :workbench_referential, metadatas: [create(:referential_metadata, lines: [line])] }

  let(:control_attributes){
    {}
  }

  let(:criticity){ "warning" }
  let(:compliance_check_set){ create :compliance_check_set, referential: referential}
  let(:compliance_check){
    create :compliance_check,
      iev_enabled_check: false,
      compliance_control_name: "RouteControl::BorderCount",
      control_attributes: control_attributes,
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  context "when route stays in the same country" do
    before do
      route = create :route, line: line
      route.stop_areas.update_all country_code: :fr
    end
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when the route changes country once" do
    context "without border" do
      before do
        route = create :route, line: line, stop_points_count: 0
        stop_areas = []
        stop_areas << create(:stop_area, country_code: :fr)
        stop_areas << create(:stop_area, country_code: :fr)
        stop_areas << create(:stop_area, country_code: :de)
        stop_areas.each do |s|
          route.stop_points.create stop_area: s
        end
      end
      it "should not pass" do
        expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
        resource = ComplianceCheckResource.last
        expect(resource.status).to eq "WARNING"
      end
    end
  end

  context "with missing borders" do
    before do
      route = create :route, line: line, stop_points_count: 0
      stop_areas = []
      stop_areas << create(:stop_area, country_code: :fr)
      stop_areas << create(:stop_area, country_code: :fr, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :de)
      stop_areas.each do |s|
        route.stop_points.create stop_area: s
      end
    end
    it "should not pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "WARNING"
    end
  end

  context "with the right borders" do
    before do
      route = create :route, line: line, stop_points_count: 0
      stop_areas = []
      stop_areas << create(:stop_area, country_code: :fr)
      stop_areas << create(:stop_area, country_code: :fr, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :de, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :de)
      stop_areas.each do |s|
        route.stop_points.create stop_area: s
      end
    end
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end

  context "when the route changes country twice" do
    context "without border" do
      before do
        route = create :route, line: line, stop_points_count: 0
        stop_areas = []
        stop_areas << create(:stop_area, country_code: :fr)
        stop_areas << create(:stop_area, country_code: :de)
        stop_areas << create(:stop_area, country_code: :gb)
        stop_areas.each do |s|
          route.stop_points.create stop_area: s
        end
      end
      it "should not pass" do
        expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
        resource = ComplianceCheckResource.last
        expect(resource.status).to eq "WARNING"
      end
    end
  end

  context "with missing borders" do
    before do
      route = create :route, line: line, stop_points_count: 0
      stop_areas = []
      stop_areas << create(:stop_area, country_code: :fr)
      stop_areas << create(:stop_area, country_code: :fr, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :de, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :de)
      stop_areas << create(:stop_area, country_code: :gb)
      stop_areas.each do |s|
        route.stop_points.create stop_area: s
      end
    end
    it "should not pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "WARNING"
    end
  end

  context "with the right borders" do
    before do
      route = create :route, line: line, stop_points_count: 0
      stop_areas = []
      stop_areas << create(:stop_area, country_code: :fr)
      stop_areas << create(:stop_area, country_code: :fr, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :de, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :de)
      stop_areas << create(:stop_area, country_code: :de, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :gb, kind: :non_commercial, area_type: :border)
      stop_areas << create(:stop_area, country_code: :gb)
      stop_areas.each do |s|
        route.stop_points.create stop_area: s
      end
    end
    it "should pass" do
      expect{compliance_check.process}.to change{ComplianceCheckResource.count}.by 1
      resource = ComplianceCheckResource.last
      expect(resource.status).to eq "OK"
    end
  end
end
