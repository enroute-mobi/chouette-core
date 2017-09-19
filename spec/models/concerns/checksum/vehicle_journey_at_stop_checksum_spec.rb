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
  

  context 'its checksum does not depend on different dates' do
    let( :today_arrival ){ Time.now.beginning_of_day + 1.hour }
    let( :today_departure ){ today_arrival + 1.minute }
    let( :yesterday_arrival ){ today_arrival.yesterday }
    let( :yesterday_departure ){ today_departure.yesterday }
    
    let( :today ){ create factory, arrival_time: today_arrival, departure_time: today_departure }
    let( :yesterday ){ create factory, arrival_time: yesterday_arrival, departure_time: yesterday_departure }

    it do
      today_checksum = today.checksum
      expect( yesterday.checksum ).to eq(today_checksum)
    end


    
  end
end
