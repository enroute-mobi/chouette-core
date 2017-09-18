require 'support/helpers/data_modifier'
include Support::Helpers::DataModifier

shared_examples 'checksummed model' do
  let( :reference ){ create factory, **base_atts }
  it 'creates checksums depending on certain attribute values' do
    # Same data --> same checksum
    expect( create(factory, **base_atts).checksum ).to eq(reference.checksum)
    # Same checksum related data --> same checksum
    expect( create(factory, **same_checksum_atts).checksum ).to eq(reference.checksum)
    # Different checksum related data --> different checksum
    modify_atts(base_atts).each do | delta_atts |
      expect( create(factory, **delta_atts).checksum ).not_to eq(reference.checksum)
    end
  end
end
