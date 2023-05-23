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
end
