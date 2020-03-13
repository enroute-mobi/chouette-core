
RSpec.describe PublicationApiKey, type: :model do
  it { should belong_to :publication_api }
  it { should validate_presence_of :name }

  it 'should generate token' do
    p = PublicationApiKey.new publication_api: create(:publication_api), name: 'Demo'
    expect{ p.save }.to change{ p.token }
    expect(p.token).to_not be_nil
  end
end
