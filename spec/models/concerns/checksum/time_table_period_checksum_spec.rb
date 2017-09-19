include Support::DataModifier

RSpec.describe Chouette::TimeTablePeriod, type: :checksum do

  # N.B. Not using 'checksummed model' shared behavior for complicate constraint management

  let( :reference ){ create :time_table_period }
  let!( :reference_checksum ){ reference.checksum }

  it 'creates checksums depending on certain attribute values' do
    # Need to delete reference to have the same date available
    period_start = reference.period_start
    period_end   = reference.period_end
    reference.destroy

    # Same checksum data --> same checksum
    same_object = create(:time_table_period, period_start: period_start, period_end: period_end)
    expect(same_object.checksum).to eq(reference_checksum)

    # C.f. above
    same_object.destroy

    # Same checksum related data --> same checksum
    same_att_object = create(:time_table_period, period_start: period_start, period_end: period_end, position: random_int)
    expect( same_att_object.checksum ).to eq(reference_checksum)

    # Different checksum related data --> different checksum
    modify_atts(period_start: period_start, period_end: period_end).each do | delta_atts |
      expect( create(:time_table_period, **Box.unbox( delta_atts )).checksum ).not_to eq(reference_checksum)
    end
  end
end
