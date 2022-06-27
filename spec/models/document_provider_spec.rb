RSpec.describe DocumentProvider, type: :model do
  it { should belong_to(:workbench).required }
  it { should have_many :documents }
  it { should validate_presence_of :name }
end
