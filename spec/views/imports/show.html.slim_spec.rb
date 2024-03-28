RSpec.describe '/imports/show', type: :view do
  let(:workbench){ create :workbench }
  let(:workbench_import){ create :workbench_import, workbench: workbench }
  let(:resource){ create :import_resource, import: workbench_import }
  let!( :messages ) {[
    create(:corrupt_zip_file, resource: resource),
    create(:inconsistent_zip_file, resource: resource),
  ]}


  before do
    assign :import, workbench_import.decorate( context: {workbench: workbench} )
    assign :workbench, workbench
    allow(view).to receive(:parent).and_return(workbench)
    allow(view).to receive(:resource).and_return(workbench_import)
    allow(view).to receive(:resource_class).and_return(Import::Workbench)
    render
  end

  it 'shows the correct record...' do
    # ... zip file name
    expect(rendered).to have_selector('.dl-def') do
      with_text workbench_import.file
    end

    # ... messages
    messages.each do | message |
      # require 'htmlbeautifier'
      # b = HtmlBeautifier.beautify(rendered, indent: '  ')
      expect(rendered).to have_selector('.import_message-list li') do
        with_text rendered_message( message )
      end
    end
  end

  def rendered_message message
    return I18n.t message.message_key, message.message_attributes.symbolize_keys
  end

end
