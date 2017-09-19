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
  
end
