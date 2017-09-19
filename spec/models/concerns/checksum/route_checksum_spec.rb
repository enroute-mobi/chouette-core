EnumBox = Support::DataModifier::EnumBox

RSpec.describe Chouette::Route, type: :checksum do
  let( :factory ){ :route }

  let( :base_atts ){{
    name: 'sixty six',
    published_name: 'ninty nine',
    wayback: EnumBox.new(:inbound, :outbound)
  }}

  let( :same_checksum_atts ){ base_atts.merge( object_version: base_atts.fetch(:object_version, 0).succ )  }
  it_behaves_like 'checksummed model'

  context 'stop areas influence checksum too' do 
    let( :route ){ create factory }

    it 'as follows' do
      current_checksum = route.checksum
      sa = route.stop_points.first.stop_area
      sa.update objectid: "#{sa.objectid}a"
      expect( route.update_checksum.checksum ).not_to eq(current_checksum)
      current_checksum = route.checksum
      
      sp = route.stop_points.first
      sp.update for_boarding: 'normal' 
      expect( route.update_checksum.checksum ).not_to eq(current_checksum)
      current_checksum = route.checksum

      sp.update for_alighting: 'normal'
      expect( route.update_checksum.checksum ).not_to eq(current_checksum)
    end
  end

  context 'routing constraint zones checksums' do 
    let( :route ){ create factory }
    let!( :routing_constraint_zone ){ create :routing_constraint_zone, route: route }

    it 'influence route\'s checksums' do
      current_checksum = route.checksum
      routing_constraint_zone.update checksum: random_hex
      expect( route.update_checksum.checksum ).not_to eq(current_checksum)
    end
  end
end
