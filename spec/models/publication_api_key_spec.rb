# frozen_string_literal: true

RSpec.describe PublicationApiKey, type: :model do
  let(:context) do
    Chouette.create do
      publication_api
    end
  end
  let(:publication_api) { context.publication_api }

  it { should belong_to :publication_api }
  it { should validate_presence_of :name }

  it 'should generate token' do
    api_key = publication_api.api_keys.new(name: 'Demo')
    expect { api_key.save }.to(change { api_key.token })
    expect(api_key.token).to_not be_nil
  end
end
