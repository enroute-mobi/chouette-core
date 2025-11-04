# frozen_string_literal: true

RSpec.describe Destination::Icar, type: :model do
  subject(:destination) do
    Destination::Icar.create!(
      name: 'ICAR',
      site_id: '42',
      site_name: 'TEST_SITE',
      file_type: 'T',
      icar_token: icar_token
    )
  end

  let(:icar_token) { 'eyJhbGciOiJIUzI1NiIXVCJ9TJV...r7E20RMHrHDcEfxjoYZgeFONFh7HgQ' }

  describe '#transmit' do
    let(:context) do
      Chouette.create do
        workgroup export_types: ['Export::NetexGeneric'] do
          workbench do
            referential
          end
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:workgroup) { workbench.workgroup }
    let(:referential) { context.referential }
    let(:operation) { create(:aggregate, referentials: [referential], new: referential) }
    let(:export_file_fixture) { 'OFFRE_TRANSDEV_2017030112251.zip' }
    let(:export_file) { fixture_file_upload(export_file_fixture) }
    let(:export) do
      Export::NetexGeneric.create!(
        name: 'Test',
        creator: 'test',
        referential: referential,
        workgroup: workgroup,
        workbench: workbench,
        setup: {
          scope_setup: { type: 'Export::Setup::Scope::Referential' },
          profile: 'idfm/icar',
          profile_options: {
            'site_id' => '42',
            'site_name' => 'RDMANTOIS',
            'file_type' => 'total'
          }
        },
        file: export_file
      )
    end
    let(:publication) { create(:publication, parent: operation, export: export) }
    let(:api_result) do
      {
        status: 200,
        headers: { 'Content-Type' => 'text/plain' },
        body: "Le fichier d'alimentation a bien \xC3\xA9t\xC3\xA9 transf\xC3\xA9r\xC3\xA9"
      }
    end

    before do
      allow_any_instance_of(Net::HTTP::Post).to receive(:body=).and_wrap_original do |m, *args|
        @request_body = args[0]
        m.call(*args)
      end
      stub_request(:post, destination.icar_import_url) \
        .with(headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{icar_token}" }) \
        .to_return(api_result)
    end

    subject { destination.transmit(publication) }

    context 'when file is attached to export' do
      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should send file to ICAR' do
        year = Time.zone.today.year + 2
        Timecop.freeze(Time.new(year, 6, 16, 11, 13, 15, '+02:00')) do
          subject
          expect(a_request(:post, destination.icar_import_url)).to have_been_made.once
          expect(JSON.parse(@request_body)).to eq(
            {
              'nomFichier' => "ARRET_42_TEST_SITE_T_#{year}0616T091315Z.zip",
              'content' => Base64.encode64(file_fixture(export_file_fixture).read)
            }
          )
        end
      end

      context 'when API returns an error' do
        let(:api_result) do
          {
            status: 400,
            headers: { 'Content-Type' => 'text/plain' },
            body: 'Le nom du fichier ne respecte pas la nomenclature attendue'
          }
        end

        it 'should fail' do
          subject
          expect(destination.reports.count).to eq(1)
          expect(destination.reports.first).to be_failed
          expect(destination.reports.first.error_message).to(
            eq('Unexpected response from ICAR API: 400 (text/plain)')
          )
        end
      end
    end
  end
end
