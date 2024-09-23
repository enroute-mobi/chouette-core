# frozen_string_literal: true

RSpec.describe '/publication_apis/show', type: :view do
  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup owner: organisation, export_types: ['Export::Gtfs'] do
        workbench organisation: organisation do
          referential
        end
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:workgroup) { workbench.workgroup }
  let(:referential) { context.referential }
  let(:export_file) { nil }
  let(:export) do
    Export::Gtfs.create!(
      name: 'Test',
      creator: 'test',
      referential: referential,
      workgroup: workgroup,
      workbench: workbench,
      file: export_file
    )
  end
  let(:publication_api_sources) { [] }
  let(:publication_api) do
    create(:publication_api, workgroup: workgroup, publication_api_sources: publication_api_sources)
  end

  before do
    assign :publication_api, publication_api.decorate(context: { workbench: workbench })
    assign :workgroup, workgroup
    assign :publication_api_sources, publication_api.publication_api_sources
    assign :api_keys, []
    allow(view).to receive(:resource).and_return(publication_api)
    allow(view).to receive(:resource_class).and_return(PublicationApi)
    render
  end

  context 'with documents' do
    let(:export_file) { fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip') }
    let(:publication_api_sources) do
      [build(:publication_api_source, publication_api: nil, key: 'gtfs.zip', export: export)]
    end

    it 'should display a download link' do
      expect(rendered).to include('actions.download'.t)
    end

    context 'when no file is attached to export' do
      let(:export_file) { nil }

      it 'should not display a download link' do
        expect(rendered).to_not include('actions.download'.t)
      end
    end
  end
end
