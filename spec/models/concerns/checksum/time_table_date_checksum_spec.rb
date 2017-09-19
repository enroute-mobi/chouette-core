include Support::DataModifier

RSpec.describe Chouette::TimeTableDate, type: :checksum do

  # N.B. Not using 'checksummed model' shared behavior for complicate constraint management

  let( :reference ){ create :time_table_date }
  let!( :reference_checksum ){ reference.checksum }

  it 'creates checksums depending on certain attribute values' do
    # Need to delete reference to have the same date available
    date = reference.date
    in_out = reference.in_out
    reference.destroy

    # Same checksum data --> same checksum
    same_object = create(:time_table_date, date: date)
    expect(same_object.checksum).to eq(reference_checksum)

    # C.f. above
    same_object.destroy

    # Same checksum related data --> same checksum
    same_att_object = create(:time_table_date, date: date, position: random_int)
    expect( same_att_object.checksum ).to eq(reference_checksum)

    # Different checksum related data --> different checksum
    modify_atts(date: date, in_out: BoolBox.new(in_out)).each do | delta_atts |
      expect( create(:time_table_date, **Box.unbox( delta_atts )).checksum ).not_to eq(reference_checksum)
    end
  end
end
