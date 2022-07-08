describe Chouette::Footnote, type: :model do
  let(:context) { Chouette.create { footnote } }
  subject(:footnote) { context.footnote }

  before { context.referential.switch }

  it { is_expected.to validate_presence_of :line }

  describe '#data_source_ref' do
    subject { footnote.data_source_ref }
    context "when data source ref is specified" do
      let(:context) { Chouette.create { footnote data_source_ref: "dummy" } }

      it "should use a default value" do
        is_expected.to eq("dummy")
      end
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
