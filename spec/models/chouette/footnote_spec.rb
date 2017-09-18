describe Chouette::Footnote, type: :model do
  let(:footnote) { create(:footnote) }
  it { should validate_presence_of :line }

  describe 'data_source_ref' do
    it 'should set default if omitted' do
      expect(footnote.data_source_ref).to eq "DATASOURCEREF_EDITION_BOIV"
    end

    it 'should not set default if not omitted' do
      source = "RANDOM_DATASOURCE"
      object = build(:footnote, data_source_ref: source)
      object.save
      expect(object.data_source_ref).to eq source
    end
  end

  describe 'checksum' do

    context '#checksum_attributes' do
      it 'should return code and label' do
        expected = [footnote.code, footnote.label]
        expect(footnote.checksum_attributes).to include(*expected)
      end

      it 'should not return other atrributes' do
        expect(footnote.checksum_attributes).to_not include(footnote.updated_at)
      end
    end
  end
end
