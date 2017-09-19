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
    let( :route1 ){ create factory }

    it 'as follows' do
      current_checksum = route1.checksum
      sa = route1.stop_points.first.stop_area
      sa.update objectid: "#{sa.objectid}a"
      expect( route1.update_checksum.checksum ).not_to eq(current_checksum)
      current_checksum = route1.checksum
      
      sp = route1.stop_points.first
      sp.update for_boarding: 'normal' 
      expect( route1.update_checksum.checksum ).not_to eq(current_checksum)
      current_checksum = route1.checksum

      sp.update for_alighting: 'normal'
      expect( route1.update_checksum.checksum ).not_to eq(current_checksum)
    end
  end
end
