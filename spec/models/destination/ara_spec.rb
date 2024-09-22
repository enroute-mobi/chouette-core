# frozen_string_literal: true

RSpec.describe Destination::Ara, type: :model do
  subject(:destination) do
    Destination::Ara.create!(
      name: 'Ara',
      ara_url: 'https://test.com',
      credentials: 'TOKEN'
    )
  end

  describe '#force_import' do
    subject { destination.force_import }

    context 'when use default value' do
      let(:destination) { Destination::Ara.new  }

      it { is_expected.to be_truthy }
    end

    context 'when a value is provided' do
      let(:destination) { Destination::Ara.new force_import: false  }

      it { is_expected.to be_falsey }
    end
  end

  describe '#use_ssl?' do
    subject { destination.use_ssl? }

    context 'when URL is http://test.com' do
      let(:destination) { Destination::Ara.new ara_url: 'http://test.com' }

      it { is_expected.to be_falsey }
    end

    context 'when URL is https://test.com' do
      let(:destination) { Destination::Ara.new ara_url: 'https://test.com' }

      it { is_expected.to be_truthy }
    end
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
      allow_any_instance_of(Net::HTTP::Post).to receive(:set_form).and_wrap_original do |m, *args|
        @ara_request_body = args[0]
        m.call(*args)
      end
      stub_request(:post, 'https://test.com/import') \
        .with(headers: { 'Authorization' => 'Token token=TOKEN' }) \
        .to_return(api_result)
    end

    subject { destination.transmit(publication) }

    # TODO: crashes when trying to cache file
    xcontext 'when no file is attached to export' do
      let(:export_file) { nil }

      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should not send file to ara' do
        subject
        expect(a_request(:post, 'https://test.com/import')).to_not have_been_made
      end
    end

    context 'when file is attached to export' do
      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should send file to ara' do
        subject
        expect(a_request(:post, 'https://test.com/import')).to have_been_made.once
        expect(@ara_request_body).to match_array([['request', { force: true }.to_json], ['data', be_present]])
        expect(File.read(@ara_request_body.detect { |p| p[0] == 'data' }[1].path)).to eq(read_fixture(export_file_path))
      end
    end
  end
end
