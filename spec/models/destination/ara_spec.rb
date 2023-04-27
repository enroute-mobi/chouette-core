RSpec.describe Destination::Ara, type: :model do
  subject { destination.use_ssl? }

  context 'url with http' do
    let(:destination) { Destination::Ara.new ara_url: 'http://test.com' }

    it { is_expected.to be_falsey }
  end

  context 'url with https' do
    let(:destination) { Destination::Ara.new ara_url: 'https://test.com' }

    it { is_expected.to be_truthy }
  end
end


