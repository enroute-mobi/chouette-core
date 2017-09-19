RSpec.describe Chouette::TimeTable, type: :checksum do

  let( :factory ){ :time_table }
  
  let( :base_atts ){ { int_day_types: 0 } }
  let( :same_checksum_atts ){ base_atts.merge(creator_id: random_string) }


  it_behaves_like 'checksummed model'
end
