RSpec.describe DocumentProvider, type: :model do
  it { should belong_to(:workbench).required }
  it { should have_many :documents }
  it { should validate_presence_of :name }

  describe '#short_name' do
    let(:workbench) { create(:workbench) }
    subject { DocumentProvider.create short_name: short_name, name: 'doc provider', workbench: workbench }

    context 'when short name is not in the validation format' do
      let(:short_name) { 'INVALID SHORT NAME' }

      it { is_expected.not_to be_valid }
    end

    context 'when short name is in the validation format' do
      let(:short_name) { 'VALID_SHORT_NAME' }

      it { is_expected.to be_valid }
    end
  end

  describe '#used?' do
    subject { document_provider.used? }

    let(:context) do
      Chouette.create do
        workbench do
          document_provider :document_provider
        end
      end
    end
    let(:document_provider) { context.document_provider(:document_provider) }

    it { is_expected.to eq(false) }

    context 'when document provider has documents' do
      let(:context) do
        Chouette.create do
          workbench do
            document_provider :document_provider
            document document_provider: :document_provider
          end
        end
      end

      it { is_expected.to eq(true) }
    end
  end
end
