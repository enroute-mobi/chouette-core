# frozen_string_literal: true

RSpec.describe '/imports/show', type: :view do
  let(:workbench) { create :workbench }
  let(:workbench_import) { create :workbench_import, workbench: workbench }
  let(:resource) { create :import_resource, import: workbench_import }
  let!(:messages) do
    [
      create(:corrupt_zip_file, resource: resource),
      create(:inconsistent_zip_file, resource: resource)
    ]
  end

  before do
    assign :import, workbench_import.decorate(context: { workbench: workbench })
    assign :workbench, workbench
    allow(view).to receive(:parent).and_return(workbench)
    allow(view).to receive(:resource).and_return(workbench_import)
    allow(view).to receive(:resource_class).and_return(Import::Workbench)
    render
  end

  it 'shows the correct record...' do
    # ... zip file name
    expect(rendered).to have_selector('.dl-def') { |r| r.text == workbench_import.file.filename.to_s }

    # ... messages
    messages.each do |message|
      expect(rendered).to have_selector('.import_message-list li') { rendered_message(message) }
    end
  end

  def rendered_message(message)
    I18n.t(message.message_key, message.message_attributes.symbolize_keys)
  end
end
