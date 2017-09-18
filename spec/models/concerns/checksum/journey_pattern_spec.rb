RSpec.describe Chouette::JourneyPattern do

  let( :factory ){ :journey_pattern }
  let( :base_atts ){{
    name: 'JP one',
    published_name: 'JP_one',
    registration_number: 'one'
  }}

  let( :same_checksum_atts ){ base_atts.merge( object_version: base_atts.fetch(:object_version, 0).succ )  }
  
  it_behaves_like 'checksummed model'
end
