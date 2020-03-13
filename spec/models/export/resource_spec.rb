
RSpec.describe Export::Resource, :type => :model do
  it { should belong_to(:export) }

  it { should enumerize(:status).in("OK", "ERROR", "WARNING", "IGNORED") }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:resource_type) }

  describe 'states' do
    let(:export_resource) { create(:export_resource) }

    it 'should initialize with new state' do
      expect(export_resource.status).to eq("WARNING")
    end
  end
end
