
RSpec.describe PublicationSetup, type: :model do
  it { should belong_to :workgroup }
  it { should have_many :destinations }
  it { should have_many :publications }
  it { should validate_presence_of :name }
  it { should validate_presence_of :workgroup }
  it { should validate_presence_of :export_type }

  describe '#publish' do
    let(:publication_setup) { create :publication_setup }
    let(:referential) { create :referential }
    let(:operation) { create :aggregate, new: referential }

    it 'should create a Publication' do
      expect{ publication_setup.publish(operation) }.to change{ publication_setup.publications.count }.by 1
    end
  end
end
