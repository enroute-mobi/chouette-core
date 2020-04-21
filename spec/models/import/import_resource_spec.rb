
RSpec.describe Import::Resource, :type => :model do
  it { should belong_to(:import) }

  it { should enumerize(:status).in("OK", "ERROR", "WARNING", "IGNORED") }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:resource_type) }

  describe 'states' do
    let(:import_resource) { create(:import_resource) }

    it 'should initialize with new state' do
      expect(import_resource.status).to eq("WARNING")
    end
  end
end
