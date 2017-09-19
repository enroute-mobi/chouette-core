include Support::DataModifier

RSpec.describe Chouette::VehicleJourneyAtStop, type: :checksum do

  let( :zero_one ){ EnumBox.new(0, 1) }
  let( :arrival_time ){ Time.now }

  let( :alightings ){ EnumBox.new(*[reference.for_alighting, nil, 'normal' 'forbidden' 'request_stop' 'is_flexible'].uniq) }


  let( :factory ){ :vehicle_journey_at_stop }
  
  let( :base_atts ){{
    departure_time: arrival_time + 1.second,
    arrival_time:   arrival_time, 
    departure_day_offset: zero_one,
    arrival_day_offset: zero_one 
  }}
  let( :same_checksum_atts ){ base_atts.merge(for_alighting: alightings) }

  it_behaves_like 'checksummed model'
  
end
