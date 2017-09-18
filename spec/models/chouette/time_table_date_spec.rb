RSpec.describe Chouette::TimeTableDate do

  describe 'checksum' do
    it_behaves_like 'checksum support', :time_table_date
  end
  
end
