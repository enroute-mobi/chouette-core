# frozen_string_literal: true

RSpec.describe Source do
  it "should be a public model (stored into 'public.sources')" do
    expect(Source.table_name).to eq('public.sources')
  end

  it { is_expected.to belong_to(:scheduled_job).class_name('::Delayed::Job').dependent(:destroy) }
  it { is_expected.to enumerize(:retrieval_frequency).in(:none, :hourly, :daily).with_default(:none) }

  describe '.next_retrieval' do
    subject { source.next_retrieval }
    let(:source) { Source.new }

    context 'when retrieval frequency is none' do
      before { source.retrieval_frequency = 'none' }
      it { is_expected.to be_nil }
    end

    context "when retrieval frequency isn't none" do
      before { source.retrieval_frequency = 'daily' }

      context 'no ScheduleJob is defined' do
        it { is_expected.to be_nil }
      end

      context 'a ScheduleJob is defined with run_at at "2030-01-01 12:00"' do
        before do
          source.scheduled_job = Delayed::Job.new
          allow(source.scheduled_job).to receive(:run_at).and_return(Date.parse('2030-01-01 12:00'))
        end

        it { is_expected.to eq(source.scheduled_job.run_at) }
      end
    end
  end

  describe '#retrieve' do
    let(:context) { Chouette.create { source retrieval_frequency: 'daily' } }
    let(:source) { context.source }

    subject { source.retrieve }

    context 'when ignore_checksum is enabled' do
      let(:retrieval) { source.retrievals.create creator: 'test' }

      before { source.update ignore_checksum: true }

      it 'should return true for checksum_changed?' do
        expect(retrieval.checksum_changed?).to eq(true)
      end
    end

    context 'when the number of records is greater than 20' do
      before do
        30.times do
          source.retrievals.create creator: 'Source'
        end
      end

      it 'should enqueue the operation and not keep more than 20 retrievals' do
        expect { subject }.to change { source.retrievals.count }.from(30).to(20)
      end
    end

    context 'when import options contain processing options' do
      before do
        source.update import_options: source.import_options
                                            .merge({
                                                     'process_gtfs_route_ids' => ['LR100|20181016', 'LR112|20181112'],
                                                     'process_gtfs_ignore_parents' => true
                                                   })
      end

      let(:import_workbench_options) { source.retrievals.last.send(:import_workbench_options) }

      it "should remove all options prefixed by 'process_' beforce create import" do
        subject

        expect(import_workbench_options).not_to match(hash_including('process_gtfs_route_ids',
                                                                     'process_gtfs_ignore_parents'))
      end
    end
  end

  describe '#downloader_class' do
    let(:source) { Source.new }
    subject { source.downloader_class }
    context 'when downloader_type is nil' do
      before { source.downloader_type = nil }
      it { is_expected.to eq(Source::Downloader::URL) }
    end
    context 'when downloader_type is :direct' do
      before { source.downloader_type = :direct }
      it { is_expected.to eq(Source::Downloader::URL) }
    end
    context 'when downloader_type is :french_nap' do
      before { source.downloader_type = :french_nap }
      it { is_expected.to eq(Source::Downloader::FrenchNap) }
    end
  end

  describe '#candidate_line_providers' do
    let(:context) do
      Chouette.create do
        workbench :workbench do
          line_provider :first, name: 'first'
          line_provider :second, name: 'second'
        end
      end
    end

    let(:workbench) { context.workbench(:workbench) }

    let(:source) { Source.new workbench: workbench }
    subject { source.candidate_line_providers.map(&:name).join(', ') }

    it 'should include all line providers of workbench with order' do
      is_expected.to eq('default, first, second')
    end
  end
end

RSpec.describe Source::Retrieval do
  let(:source) { Source.new }
  subject(:retrieval) { Source::Retrieval.new source: source }

  describe '#import_workbench_options' do
    subject { retrieval.import_workbench_options }

    it 'includes Source import_options' do
      source.import_options = { dummy: true }
      is_expected.to include(source.import_options)
    end

    it 'exclude Source processing options' do
      source.import_options = { dummy: true, process_option_1: 'excluded' }
      is_expected.to_not include('process_option_1' => 'excluded')
    end

    context 'when downloaded file is an XML file' do
      before { allow(retrieval).to receive(:downloaded_file_type).and_return(double('xml?' => true)) }
      it { is_expected.to include(import_category: 'netex_generic') }
    end
  end

  describe '#import_attributes' do
    subject { retrieval.import_attributes }

    describe 'import_category' do
      it { is_expected.to include(import_category: nil) }

      context 'when downloaded file is an XML file' do
        before { allow(retrieval).to receive(:downloaded_file_type).and_return(double('xml?' => true)) }
        it { is_expected.to include(import_category: 'netex_generic') }
      end
    end
  end

  describe '#processing_options' do
    subject { retrieval.processing_options }

    it 'include all import options with a key starting with process_' do
      source.import_options = { not_process_option: 'excluded', process_option_1: 'included' }.stringify_keys
      is_expected.to include('process_option_1' => 'included')
    end
  end

  describe '#downloaded_file_type' do
    subject { retrieval.downloaded_file_type }
    context 'when downloaded file is an XML file' do
      before { allow(retrieval).to receive(:downloaded_file).and_return(open_fixture('reflex.xml')) }
      it { is_expected.to be_xml }
    end

    context 'when downloaded file is an ZIP file' do
      before { allow(retrieval).to receive(:downloaded_file).and_return(open_fixture('reflex_updated.zip')) }
      it { is_expected.to be_zip }
    end
  end

  describe '#checksum' do
    subject { retrieval.checksum }
    context 'when downloaded file is an XML file' do
      before { allow(retrieval).to receive(:downloaded_file).and_return(open_fixture('reflex.xml')) }
      it { is_expected.to match(/^[0-9a-f]{64}$/) }
    end

    context 'when downloaded file is an ZIP file' do
      before { allow(retrieval).to receive(:downloaded_file).and_return(open_fixture('reflex_updated.zip')) }
      it { is_expected.to match(/^[0-9a-f]{64}$/) }
    end
  end
end

RSpec.describe Source::Downloader::URL do
  subject(:downloader) { Source::Downloader::URL.new('http://chouette.test') }

  describe '#download' do
    let(:path) { Tempfile.new.path }

    it 'uses a (read) timeout of 120 seconds' do
      expect(Source::Downloader::Fetcher)
        .to receive(:new).with(downloader.url, {}, read_timeout: 120).and_return(double(fetch: true))

      downloader.download(path)
    end
  end
end

RSpec.describe Source::ScheduledJob do
  subject(:job) { Source::ScheduledJob.new(source) }
  let(:source) { Source.new }

  describe '#cron' do
    subject { job.cron }

    context 'when frequency is none' do
      it { is_expected.to be_nil }
    end

    context 'when frequency is daily' do
      before { source.retrieval_frequency = 'daily' }

      context 'when Source retrieval_time_of_day is 7:30' do
        before { source.retrieval_time_of_day = TimeOfDay.new(7, 30) }

        it { is_expected.to eq('30 7 * * *') }
      end

      context 'when Source retrieval_time_of_day isn\'t defined' do
        before { source.retrieval_time_of_day = nil }

        it { is_expected.to be_nil }
      end
    end

    context 'when frequency is hourly' do
      before { source.retrieval_frequency = 'hourly' }

      context 'when #hourly_random returns 61' do
        before { allow(job).to receive(:hourly_random).and_return(61) }
        it { is_expected.to eq('1 * * * *') }
      end
    end
  end

  describe '#hourly_random' do
    subject { job.hourly_random }

    context 'when the Source id is 42' do
      before { source.id = 42 }

      it { is_expected.to eq(42) }
    end

    context "when the Source id isn't defined" do
      context 'when the random value is 42' do
        before { allow(Random).to receive(:rand).with(60).and_return(42) }

        it { is_expected.to eq(42) }
      end
    end
  end

  describe '#retrieval_days_of_week' do
    subject { job.retrieval_days_of_week_cron }

    context 'when selected Day of Week is Monday"' do
      before do
        source.retrieval_days_of_week = Timetable::DaysOfWeek.none.enable(:monday)
      end

      it { is_expected.to eq('mon') }
    end

    context 'when selected Days of Week are Monday and Sunday"' do
      before do
        source.retrieval_days_of_week = Timetable::DaysOfWeek.none.enable(:monday).enable(:sunday)
      end

      it { is_expected.to eq('mon,sun') }
    end

    context 'when all Days of Week are selected' do
      before do
        source.retrieval_days_of_week = Timetable::DaysOfWeek.all
      end

      it { is_expected.to eq('*') }
    end
  end

  describe '#import_option_line_provider_id' do
    let(:context) { Chouette.create { source retrieval_frequency: 'daily' } }
    let(:source) { context.source }

    subject { source.import_option_line_provider }

    context 'when no line_provider_id option is defined' do
      before { source.import_options['line_provider_id'] = nil }

      it 'uses Workbench default line provider' do
        is_expected.to eq(source.workbench.default_line_provider)
      end
    end

    context 'when line_provider_id option matches one of the candidate line providers' do
      before { source.import_options['line_provider_id'] = line_provider.id }

      let(:line_provider) { source.candidate_line_providers.first }

      it 'uses the candidate line provider' do
        is_expected.to eq(line_provider)
      end
    end

    context "when line_provider_id option doesn't match one of the candidate providers" do
      before { source.import_options['line_provider_id'] = 42 }

      it 'uses Workbench default line provider' do
        is_expected.to eq(source.workbench.default_line_provider)
      end
    end
  end
end
