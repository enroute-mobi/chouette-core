RSpec.describe Chouette::TimeTable, type: :checksum do

  let( :factory ){ :time_table }
  
  let( :base_atts ){ { int_day_types: 0 } }
  let( :same_checksum_atts ){ base_atts.merge(creator_id: random_string) }


  it_behaves_like 'checksummed model'

  context 'TimeTableDate & TimeTablePeriod influence' do 
    let( :time_table ){ create factory }

    it 'checksum of TimeTable' do
      current_checksum = time_table.checksum
      time_table.dates.last.update checksum: random_hex
      expect( time_table.update_checksum.checksum ).not_to eq(current_checksum)
      current_checksum = time_table.checksum

      time_table.periods.first.update checksum: random_hex
      expect( time_table.update_checksum.checksum ).not_to eq(current_checksum)

    end


  end
end
