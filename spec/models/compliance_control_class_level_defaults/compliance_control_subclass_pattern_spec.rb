RSpec.describe ComplianceControl do
  let( :subject ){ described_class.subclass_patterns }

  context 'subclass_patterns' do
    it 'are correctly defined' do
      expect_it.to eq(
        generic: 'Generic',
        journey_pattern: 'JourneyPattern',
        line: 'Line',
        route: 'Route',
        routing_constraint_zone: 'RoutingConstraint',
        vehicle_journey: 'VehicleJourney',
        dummy: 'Dummy',
        company: 'Company'
      )
    end
  end

end
