# frozen_string_literal: true

RSpec.describe Destination::SFTP, type: :model do
  let(:secret_file) { open_fixture('invalid_version.json') }

  let(:destination) do
    Destination::SFTP.create!(
      name: 'SFTP',
      host: '127.0.0.1',
      directory: '/dest',
      username: 'toto',
      secret_file: secret_file
    )
  end

  describe '#transmit' do
    class self::FakeSFTPSession # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
      attr_reader :args, :keys, :uploads

      def initialize(args)
        @args = args
        @keys = args[2][:keys].map { |k| File.read(k) }
        @uploads = []
      end

      def upload!(local_path, server_path)
        @uploads << [server_path, File.read(local_path)]
      end
    end

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
    let(:export_file_fixture) { 'OFFRE_TRANSDEV_2017030112251.zip' }
    let(:export_file) { fixture_file_upload(export_file_fixture) }
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

    before do
      allow(Net::SFTP).to receive(:start) do |*args, &block|
        @sftp_mock = self.class::FakeSFTPSession.new(args)
        block.call(@sftp_mock)
      end
    end

    subject { destination.transmit(publication) }

    context 'when no file is attached to export' do
      let(:export_file) { nil }

      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should send file to FTP server' do
        subject
        expect(@sftp_mock.keys).to include(secret_file.read)
        expect(@sftp_mock.uploads).to be_empty
      end
    end

    context 'when file is attached to export' do
      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should send file to FTP server' do
        subject
        expect(@sftp_mock.keys).to include(secret_file.read)
        expect(@sftp_mock.uploads).to include(
          [match(%r(\A/dest/[0-9a-f]{40}-#{export_file_fixture}\z)), read_fixture(export_file_fixture)]
        )
      end
    end
  end
end
