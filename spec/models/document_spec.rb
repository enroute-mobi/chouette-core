RSpec.describe Document, type: :model do
  it { should belong_to(:document_type).required }
  it { should belong_to(:document_provider).required }
  it { should have_many :codes }
  it { should validate_presence_of :file }
  it { should validate_presence_of :document_type_id }
  it { should validate_presence_of :document_provider_id }
end
