require 'spec_helper'

describe Chouette::Footnote, type: :model do
  subject { create(:footnote) }
  it { should validate_presence_of :line }

  describe 'data_source_ref' do
    it 'should set default if omitted' do
      expect(subject.data_source_ref).to eq "DATASOURCEREF_EDITION_BOIV"
    end

    it 'should not set default if not omitted' do
      source = "RANDOM_DATASOURCE"
      object = build(:footnote, data_source_ref: source)
      object.save
      expect(object.data_source_ref).to eq source
    end
  end

  describe 'checksum' do
    it_behaves_like 'checksum support'

    context '#checksum_attributes' do
      it 'should return code and label' do
        expected = [subject.code, subject.label]
        expect(subject.checksum_attributes).to include(*expected)
      end

      it 'should not return other atrributes' do
        expect(subject.checksum_attributes).to_not include(subject.updated_at)
      end
    end
  end
end
