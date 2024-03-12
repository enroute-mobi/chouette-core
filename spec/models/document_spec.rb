# frozen_string_literal: true

RSpec.describe Document, type: :model do
  it { should belong_to(:document_type).required }
  it { should belong_to(:document_provider).required }
  it { should have_many :codes }
  it { should have_many(:memberships) }
  it { should have_many(:lines) }
  it { should validate_presence_of :file }
  it { should validate_presence_of :document_type_id }
  it { should validate_presence_of :document_provider_id }

  describe '#document_type' do
    describe 'validations' do
      let(:context) do
        Chouette.create do
          workgroup do
            document_type :document_type
            document_provider :document_provider
          end
          workgroup do
            document_type :other_document_type
          end
        end
      end
      subject(:document) do
        context.document_provider(:document_provider).documents.new(
          name: 'test',
          file: fixture_file_upload('sample_pdf.pdf')
        )
      end

      it { is_expected.to allow_value(context.document_type(:document_type).id).for(:document_type_id) }
      it { is_expected.not_to allow_value(context.document_type(:other_document_type).id).for(:document_type_id) }
    end
  end

  describe '#validity_period_attributes=' do
    subject(:document) { Document.new }

    [
      {}, 
      { from: nil },
      { to: nil },
      { from: nil, to: nil },
      { from: '', to: '' }
    ].each do |attributes|
      context "when attributes is #{attributes.inspect}" do
        it do
          expect do
            document.validity_period_attributes = attributes 
          end.to_not change(document, :validity_period).from(nil)
        end
      end
    end

    [
      [{ from: '2030-01-01' }, Period.parse('2030-01-01..')],
      [{ from: '2030-01-01', to: '2030-12-31' }, Period.parse('2030-01-01..2030-12-31')],
      [{ to: '2030-12-31' }, Period.parse('..2030-12-31')]
    ].each do |attributes, period|
      context "when attributes is #{attributes.inspect}" do
        it do
          expect do
            document.validity_period_attributes = attributes.stringify_keys
          end.to change(document, :validity_period).to(period)
        end
      end
    end
  end
end
