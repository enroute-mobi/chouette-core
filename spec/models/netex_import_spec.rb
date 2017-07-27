RSpec.describe NetexImport, type: :model do
  it { should validate_presence_of(:referential) }
  it { should validate_presence_of(:workbench) }
end
