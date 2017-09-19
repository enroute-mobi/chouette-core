require 'support/data_modifier'
include Support::DataModifier

shared_examples 'checksummed model' do
  let( :stripped_base_atts ){ Box.unbox( base_atts )  }
  let( :stripped_same_atts ){ Box.unbox( same_checksum_atts ) }

  let( :reference ){ create factory, **stripped_base_atts }

  it 'creates checksums depending on certain attribute values' do
    # Same data --> same checksum
    expect( create(factory, **stripped_base_atts).checksum ).to eq(reference.checksum)
    # Same checksum related data --> same checksum
    expect( create(factory, **stripped_same_atts).checksum ).to eq(reference.checksum)
    # Different checksum related data --> different checksum
    modify_atts(base_atts).each do | delta_atts |
      expect( create(factory, **Box.unbox( delta_atts )).checksum ).not_to eq(reference.checksum)
    end
  end
end
