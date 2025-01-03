# frozen_string_literal: true

RSpec.describe Document, type: :model do
  it { should belong_to(:document_type).required }
  it { should belong_to(:document_provider).required }
  it { should have_many :codes }
  it { should have_many(:memberships) }
  it { should have_many(:lines) }
  it { should validate_presence_of :file }
  it { should allow_value(fixture_file_upload('sample_png.png')).for(:file) }
  it do
    message = I18n.t(
      'errors.messages.extension_whitelist_error',
      extension: '"zip"',
      allowed_types: 'pdf, kml, jpg, jpeg, png'
    )
    should_not allow_value(fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip')).for(:file).with_message(message)
  end

  describe '#document_type' do
    describe 'validations' do
      let(:context) do
        Chouette.create do
          workgroup do
            document_type :document_type
            document_provider :document_provider
          end
          workgroup do
            document_type :other_document_type
          end
        end
      end
      subject(:document) do
        context.document_provider(:document_provider).documents.new(
          name: 'test',
          file: fixture_file_upload('sample_pdf.pdf')
        )
      end

      it { is_expected.to allow_value(context.document_type(:document_type).id).for(:document_type_id) }
      it { is_expected.not_to allow_value(context.document_type(:other_document_type).id).for(:document_type_id) }
    end
  end

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first')
    end
  end

  let(:workbench) { context.workbench }
  let(:document_provider) { workbench.document_providers.create!(name: 'document_provider_name', short_name: 'titi') }
  let(:document_type) { workbench.workgroup.document_types.create!(name: 'document_type_name', short_name: 'toto') }
  let(:file_fixture) { 'sample_pdf.pdf' }
  let(:file) { fixture_file_upload(file_fixture) }
  let(:document) do
    Document.create!(
      name: 'test',
      document_type_id: document_type.id,
      document_provider_id: document_provider.id,
      file: file,
      validity_period: Time.zone.today...Time.zone.today + 1.day
    )
  end

  describe '#content_type' do
    subject { document.content_type }

    context 'with a PDF file' do
      it { is_expected.to eq('application/pdf') }
    end

    context 'with a JPEG file' do
      let(:file_fixture) { 'sample_jpeg.jpeg' }

      it { is_expected.to eq('image/jpeg') }
    end
  end

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

  describe 'LocalCache' do
    context 'without file storage' do
      before { allow_any_instance_of(DocumentUploader).to receive(:file_storage?).and_return(false) }
      after { FileUtils.rm(document.file.local_cache_file) }

      subject { document.file.local_cache! }

      it 'should create local cache file' do
        expect { subject }.to change { File.exist?(document.file.local_cache_file) }.from(false).to(true)
        expect(File.read(document.file.local_cache_file)).to eq(read_fixture(file_fixture))
      end

      it 'should change path from storage to cache' do
        expect { subject }.to change { document.file.path }.from(match(%r{public/uploads})).to(match(%r{/tmp}))
      end

      it 'should touch local cache file when file is already cached' do
        document.file.local_cache!
        sleep 1
        expect { subject }.to(change { File.stat(document.file.local_cache_file).mtime })
      end

      it 'should not re-create file if it already exists' do
        FileUtils.touch(document.file.local_cache_file)
        subject
        expect(File.read(document.file.local_cache_file)).to eq('')
      end

      it 'should wait for lock to be free' do
        document # instantiate document before thread start to ensure correct rollback
        t = Thread.new do
          document.file.with_local_lock do
            sleep 2
            FileUtils.touch(document.file.local_cache_file)
          end
        end
        sleep 1
        start = Time.zone.now
        subject
        expect(Time.zone.now - start).to be >= 0.99
        expect(File.read(document.file.local_cache_file)).to eq('')
      ensure
        t.exit
      end
    end

    context 'with file storage' do
      before { allow_any_instance_of(DocumentUploader).to receive(:file_storage?).and_return(true) }

      subject { document.file.local_cache! }

      it 'should create local cache file' do
        expect { subject }.to_not change { File.exist?(document.file.local_cache_file) }.from(false)
      end

      it 'should change path from storage to cache' do
        expect { subject }.to_not change { document.file.path }.from(match(%r{public/uploads}))
      end
    end

    describe '#clean_local_cache' do
      subject { LocalCache.clean_local_cache }

      let(:travel) { nil }
      let(:local_cache_cleaned_at) { 2.hours.ago }
      let(:file_path) { File.join(LocalCache.local_cache_directory, 'some_file.txt') }

      before do
        Timecop.travel(travel) if travel
        @old_local_cache_cleaned_at = LocalCache.local_cache_cleaned_at
        LocalCache.local_cache_cleaned_at = local_cache_cleaned_at
        FileUtils.touch(file_path)
      end

      after do
        LocalCache.local_cache_cleaned_at = @old_local_cache_cleaned_at
        Timecop.return
      end

      context 'when the file is not deletable' do
        it do
          expect { subject }.to(
            not_change { File.exist?(file_path) }.from(true)
                                                 .and(change { LocalCache.local_cache_cleaned_at })
          )
        end
      end

      context 'when the file is deletable' do
        let(:travel) { 33.hours.from_now }

        context 'when #clean_local_cache was run less than 1 hour ago' do
          let(:local_cache_cleaned_at) { 30.minutes.ago }

          it do
            expect { subject }.to(
              not_change { File.exist?(file_path) }.from(true)
                                                   .and(not_change { LocalCache.local_cache_cleaned_at })
            )
          end
        end

        context 'when #clean_local_cache was run more than 1 hour ago' do
          it do
            expect { subject }.to(
              change { File.exist?(file_path) }.from(true).to(false)
                                               .and(change { LocalCache.local_cache_cleaned_at })
            )
          end
        end
      end
    end
  end
end
