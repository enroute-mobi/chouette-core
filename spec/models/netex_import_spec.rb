RSpec.describe NetexImport, type: :model do
  it { should validate_presence_of :referential_id }
  it { should validate_presence_of :workbench_id }
end
