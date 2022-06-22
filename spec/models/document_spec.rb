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
  let(:document_type) { workbench.workgroup.document_types.create(name: 'document_type_name', short_name: 'toto')}
  let(:file) { fixture_file_upload('sample_pdf.pdf') }
  let(:document) { Document.create(name: 'test', document_type_id: document_type.id, document_provider_id: document_provider.id, file: file, validity_period: (Time.zone.today...Time.zone.today + 1.day)) }


end
