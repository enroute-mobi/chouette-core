RSpec.describe VehicleJourneyControl::Speed do

  let( :factory ){ :vehicle_journey_control_speed }
  subject{ build factory }

  it_behaves_like 'has min_max_values'

end
