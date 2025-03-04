# frozen_string_literal: true

RSpec.describe Destination::Chouette, type: :model do
  subject(:destination) do
    Destination::Chouette.create!(
      name: 'Chouette Saas',
      workbench_id: workbench.id,
      workbench_api_key: workbench_api_key,
      automatic_merge: true
    )
  end

  describe '#transmit' do
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
    let(:workbench_api_key) { workbench.api_keys.first.token } 
    let(:workgroup) { workbench.workgroup }
    let(:referential) { context.referential }
    let(:operation) { create(:aggregate, referentials: [referential], new: referential) }
    let(:export_file_path) { 'OFFRE_TRANSDEV_2017030112251.zip' }
    let(:export_file) { fixture_file_upload(export_file_path) }
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
    let(:publication) { create(:publication, parent: operation, export: export) }
    let(:api_result) do
      {
        status: 200,
        body: { 'Errors' => [] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }
    end

    before do
      workbench.api_keys.create
      
      allow_any_instance_of(Destination::Chouette).to(
        receive(:import_url).and_return "https://test.com/workbenches/#{workbench.id}/imports"
      )

      allow_any_instance_of(Net::HTTP::Post).to receive(:set_form).and_wrap_original do |m, *args|
        @chouette_request_body = args[0]
        m.call(*args)
      end
      stub_request(:post, "https://test.com/workbenches/#{workbench.id}/imports") \
        .with(headers: { 'Authorization' => "Token token=#{workbench_api_key}" }) \
        .to_return(api_result)
    end

    subject { destination.transmit(publication) }

    context 'when file is attached to export' do
      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should send file to Chouette' do
        subject
        expect(a_request(:post, "https://test.com/workbenches/#{workbench.id}/imports")).to have_been_made.once
        expect(@chouette_request_body).to(
          match_array([
            ['workbench_import[options][automatic_merge]', 'true'],
            ['workbench_import[options][archive_on_fail]', 'true'],
            ['workbench_import[file]', be_present],
            ['workbench_import[name]', 'Chouette Saas']
          ])
        )
      end
    end
  end
end
