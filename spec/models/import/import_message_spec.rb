
RSpec.describe Import::Message, :type => :model do
  it { should validate_presence_of(:criticity) }
  it { is_expected.to belong_to(:import).required(false) }
  it { is_expected.to belong_to(:resource).required(false) }
end
