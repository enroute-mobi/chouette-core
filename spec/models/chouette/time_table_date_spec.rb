describe Chouette::TimeTableDate, :type => :model do

  let(:subject) { build :time_table_date}

  it { is_expected.to validate_presence_of :date }
  it { is_expected.to validate_uniqueness_of(:date).scoped_to(:time_table_id)  }

end
