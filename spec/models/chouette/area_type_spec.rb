# frozen_string_literal: true

RSpec.describe Chouette::AreaType do
  describe '::ALL' do
    it 'includes all supported types' do
      expect(Chouette::AreaType::ALL).to match_array(%i[zdep zdlp lda gdl deposit flexible_stop_place border
                                                        service_area relief other])
      expect(Chouette::AreaType::COMMERCIAL).to match_array(%i[zdep zdlp lda gdl flexible_stop_place])
      expect(Chouette::AreaType::NON_COMMERCIAL).to match_array(%i[deposit border service_area relief other])
    end
  end

  describe '.find' do
    it 'returns nil if the given code is nil' do
      expect(Chouette::AreaType.find(nil)).to be_nil
    end

    it 'returns nil if the given code is unknown' do
      expect(Chouette::AreaType.find('dummy')).to be_nil
    end

    it 'returns an AreaType associated to the code' do
      expect(Chouette::AreaType.find('zdep').code).to eq :zdep
    end
  end

  describe '.options' do
    before do
      Chouette::AreaType.reset_caches!
    end

    it 'returns an array with label and code for each type' do
      allow(Chouette::AreaType).to receive(:all).and_return(%i[zdep lda])

      expected_options = [
        [Chouette::AreaType.find('zdep').label, :zdep],
        [Chouette::AreaType.find('lda').label, :lda]
      ]
      expect(Chouette::AreaType.options).to eq(expected_options)
    end
  end
end
