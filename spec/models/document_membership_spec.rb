RSpec.describe DocumentMembership, type: :model do
  it { should belong_to(:document).required(true) }
  it { should belong_to(:documentable).required(true) }
end
