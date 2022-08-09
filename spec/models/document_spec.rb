RSpec.describe Document, type: :model do
  it { should belong_to(:document_type).required }
  it { should belong_to(:document_provider).required }
  it { should have_many :codes }
  it { should have_many(:memberships) }
  it { should have_many(:lines) }
  it { should validate_presence_of :file }
  it { should validate_presence_of :document_type_id }
  it { should validate_presence_of :document_provider_id }

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        line :first
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:line) { context.line(:first) }

  let(:document_provider) { workbench.document_providers.create(name: 'document_provider_name') }
  let(:document_type) do
 workbench.workgroup.document_types.create(name: 'document_type_name', short_name: 'toto') end
  let(:file) { fixture_file_upload('sample_pdf.pdf') }
  let(:document) do
 Document.create(name: 'test', document_type_id: document_type.id,
                 document_provider_id: document_provider.id, file: file, validity_period: (Time.zone.today...Time.zone.today + 1.day)) end

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
