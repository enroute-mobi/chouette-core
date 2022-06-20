RSpec.describe DocumentMembership, type: :model do
  it { should belong_to(:document) }
  it { should belong_to(:documentable) }

  it { should validate_presence_of :document }
  it { should validate_presence_of :documentable }
end
