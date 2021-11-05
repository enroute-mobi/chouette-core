RSpec.describe Destination, type: :model do
  it { should belong_to :publication_setup }
  it { should have_many :reports }
  it { should validate_presence_of :type }
  it { should validate_presence_of :name }
end
