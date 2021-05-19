RSpec.describe ComplianceControls::ObjectPathFinder, type: :service do
  let(:compliance_check) { FactoryBot.create :compliance_check }
  let(:referential) { compliance_check.referential }

  describe '#call' do
    context 'Chouette::Company' do
      it 'should return a valid path' do
        path = described_class.call(compliance_check, Chouette::Company.new(id: 1))
        pattern = %r{workbenches/\d+/line_referential/companies/\d+}
        
        expect(path).to match(pattern)
      end
    end

    context 'Chouette::Footnote' do
      let(:footnote) { FactoryBot.create(:footnote) }
      it 'should return a valid path' do
        path = described_class.call(compliance_check, footnote)
        pattern = %r{referentials/\d+/lines/\d+/footnotes/\d+}
        
        expect(path).to match(pattern)
      end
    end

    context 'Chouette::JourneyPattern' do
      let(:journey_pattern) { FactoryBot.create(:journey_pattern) }
      it 'should return a valid path' do
        path = described_class.call(compliance_check, journey_pattern)
        pattern = %r{referentials/\d+/lines/\d+/routes/\d+/journey_patterns_collection}
        
        expect(path).to match(pattern)
      end
    end

    context 'Chouette::Line' do
      let(:line) { FactoryBot.create(:line) }
      it 'should return a valid path' do
        path = described_class.call(compliance_check, line)
        pattern = %r{referentials/\d+/lines/\d+}
        
        expect(path).to match(pattern)
      end
    end

    context 'Chouette::Route' do
      let(:route) { FactoryBot.create(:route) }
      it 'should return a valid path' do
        path = described_class.call(compliance_check, route)
        pattern = %r{referentials/\d+/lines/\d+/routes/\d+}
        
        expect(path).to match(pattern)
      end
    end

    context 'Chouette::RoutingConstraintZone' do
      let(:routing_constraint_zone) { FactoryBot.create(:routing_constraint_zone) }
      it 'should return a valid path' do
        path = described_class.call(compliance_check, routing_constraint_zone)
        pattern = %r{referentials/\d+/lines/\d+/routing_constraint_zones/\d+}
        
        expect(path).to match(pattern)
      end
    end

    context 'Chouette::StopArea' do
      let(:stop_area) { FactoryBot.create(:stop_area) }
      it 'should return a valid path' do
        path = described_class.call(compliance_check, stop_area)
        pattern = %r{workbenches/\d+/stop_area_referential/stop_areas/\d+}
        
        expect(path).to match(pattern)
      end
    end

    context 'Chouette::VehicleJourney' do
      let(:vehicle_journey) { FactoryBot.create(:vehicle_journey) }
      it 'should return a valid path' do
        path = described_class.call(compliance_check, vehicle_journey)
        pattern = %r{referentials/\d+/lines/\d+/routes/\d+/vehicle_journeys}
        
        expect(path).to match(pattern)
      end
    end
  end
end