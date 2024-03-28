# frozen_string_literal: true

RSpec.describe DocumentType, type: :model do
  it { is_expected.to belong_to(:workgroup).required(true) }
  it { is_expected.to have_many(:documents) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:short_name) }
  it { is_expected.to validate_uniqueness_of(:short_name).scoped_to(:workgroup_id) }

  it { is_expected.to allow_value('0aZ_').for(:short_name) }
  it { is_expected.not_to allow_value('').for(:short_name) }
  it { is_expected.not_to allow_value('a-Z').for(:short_name) }

  context '#used?' do
    subject { document_type.used? }

    let(:context) do
      Chouette.create do
        workgroup do
          document_type
        end
      end
    end
    let(:document_type) { context.document_type }

    it { is_expected.to eq(false) }

    context 'when document_type has documents' do
      let(:context) do
        Chouette.create do
          workgroup do
            document_type :document_type
            document document_type: :document_type
          end
        end
      end
      let(:document_type) { context.document_type(:document_type) }

      it { is_expected.to eq(true) }
    end
  end
end
