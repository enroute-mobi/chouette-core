include Support::DataModifier

RSpec.describe Chouette::VehicleJourney, type: :checksum do

  before do
    2.times{ create :company }
  end
  let( :factory ){ :vehicle_journey }

  let( :base_atts ){{
    published_journey_name: random_string,
    published_journey_identifier: random_string,
    company_id: EnumBox.new(Chouette::Company.first.id, Chouette::Company.last.id)
  }}
  let( :same_checksum_atts ){ base_atts.merge(creator_id: random_string) }

  it_behaves_like 'checksummed model'

  context 'Footnote & VehicleJourneyAtStop influence' do

    before do
      vehicle_journey.footnotes << footnote
    end
    let( :vehicle_journey ){ create factory }
    let( :footnote ){ create :footnote }


    it 'checksum of VehicleJourney' do
      current_checksum = vehicle_journey.checksum

      vehicle_journey.vehicle_journey_at_stops.first.update checksum: random_hex
      expect( vehicle_journey.update_checksum.checksum ).not_to eq(current_checksum)
      current_checksum = vehicle_journey.checksum
      
      footnote.update checksum: random_hex
      expect( vehicle_journey.update_checksum.checksum ).not_to eq(current_checksum)
    end
  end
end
