RSpec.describe Export::Message, :type => :model do
  it { should validate_presence_of(:criticity) }
  it { should belong_to(:export) }
end
