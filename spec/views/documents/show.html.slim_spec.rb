# frozen_string_literal: true

RSpec.describe '/documents/show', type: :view do
  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first') do
        line :first
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:line) { context.line(:first) }

  let(:document_provider) { workbench.document_providers.create!(name: 'document_provider_name', short_name: 'titi') }
  let(:document_type) { workbench.workgroup.document_types.create!(name: 'document_type_name', short_name: 'toto') }
  let(:file) { fixture_file_upload('sample_pdf.pdf') }
  let(:document) do
    Document.create!(
      name: 'test',
      document_type_id: document_type.id,
      document_provider_id: document_provider.id,
      file: file,
      validity_period: Time.zone.today...Time.zone.today + 1.day
    )
  end

  before do
    assign :document, document.decorate(context: { workbench: workbench })
    assign :workbench, workbench
    allow(view).to receive(:resource_class).and_return(Document)
    allow(ActiveStorage::Current).to receive(:host).and_return('http://test.ex')
    render
  end

  it 'shows the correct record...' do
    expect(rendered).to have_selector('.dl-def') { |r| r.text == 'sample_pdf.pdf' }
    expect(rendered).to have_selector('.dl-def') { |r| r.text == 'application/pdf' }
  end
end
