RSpec.describe Import::Base, type: :model do
  subject(:import) { Import::Base.new }

  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent) }

  it {
    should enumerize(:status).in('aborted', 'canceled', 'failed', 'new', 'pending', 'running', 'successful', 'warning')
  }

  it { should validate_presence_of(:workbench) }
  it { should validate_presence_of(:creator) }

  describe '.purge_imports' do
    let(:workbench) { create(:workbench) }
    let(:other_workbench) { create(:workbench) }

    it 'removes files from imports older than 60 days' do
      file_purgeable = Timecop.freeze(60.days.ago) do
        create(:workbench_import, workbench: workbench)
      end

      other_file_purgeable = Timecop.freeze(60.days.ago) do
        create(:workbench_import, workbench: other_workbench)
      end

      Import::Workbench.new(workbench: workbench).purge_imports

      expect(file_purgeable.reload.file_url).to be_nil
      expect(other_file_purgeable.reload.file_url).not_to be_nil
    end

    it 'removes imports older than 90 days' do
      old_import = Timecop.freeze(90.days.ago) do
        create(:workbench_import, workbench: workbench)
      end

      expect { Import::Workbench.new(workbench: workbench).purge_imports }.to change {
        old_import.workbench.imports.purgeable.count
      }.from(1).to(0)

      expect { Import::Workbench.new(workbench: workbench).purge_imports }.not_to(change do
        old_import.workbench.imports.purgeable.count
      end)
    end
  end

  context '#user_file' do
    before do
      subject.name = 'Dummy Import Example'
    end

    it 'uses a parameterized version of the Import name as base name' do
      expect(subject.user_file.basename).to eq('dummy-import-example')
    end

    it 'uses the Import content_type' do
      expect(subject.user_file.content_type).to eq(subject.content_type)
    end

    it 'uses the Import file_extension' do
      expect(subject.user_file.extension).to eq(subject.send(:file_extension))
    end
  end

  describe '#file_extension' do
    subject { import.send(:file_extension) }

    [
      [nil, nil],
      ['dummy', nil],
      ['application/x-zip-compressed', 'zip'],
      ['application/zip', 'zip'],
      ['application/xml', 'xml'],
      ['text/xml', 'xml']
    ].each do |content_type, expected_file_extension|
      context "when content type is #{content_type.inspect}" do
        before { allow(import).to receive(:content_type).and_return(content_type) }
        it { is_expected.to eq(expected_file_extension) }
      end
    end
  end

  describe '#line_provider' do
    let(:workbench) { context.workbench }
    let(:referential) { context.referential }

    let(:import_workbench) do
      create :workbench_import, workbench: workbench, referential: referential, options: options
    end

    let(:line_provider) do
      workbench.line_providers.create(
        short_name: 'Line_provider_2',
        name: 'Line Provider 2'
      )
    end

    let(:context) do
      Chouette.create do
        referential
      end
    end

    before do
      allow(import).to receive(:workbench).and_return(workbench)
      allow(import).to receive(:parent).and_return(import_workbench)
    end

    subject { import.line_provider }

    context 'when options contain line_provider' do
      let(:options) { { 'line_provider_id' => line_provider.id } }

      it { is_expected.to eq(line_provider) }
    end

    context "when options don't contain line_provider" do
      let(:options) { {} }

      it { is_expected.to eq(workbench.default_line_provider) }
    end
  end

  describe '#stop_area_provider' do
    let(:workbench) { context.workbench }
    let(:referential) { context.referential }

    let(:import_workbench) do
      create :workbench_import, workbench: workbench, referential: referential, options: options
    end

    let(:stop_area_provider) do
      workbench.stop_area_providers.create(
        name: 'Stop Area Provider 2'
      )
    end

    let(:context) do
      Chouette.create do
        referential
      end
    end

    before do
      allow(import).to receive(:workbench).and_return(workbench)
      allow(import).to receive(:parent).and_return(import_workbench)
    end

    subject { import.stop_area_provider }

    context 'when options contain stop_area_provider' do
      let(:options) { { 'stop_area_provider_id' => stop_area_provider.id } }

      it { is_expected.to eq(stop_area_provider) }
    end

    context "when options don't contain stop_area_provider" do
      let(:options) { {} }

      it { is_expected.to eq(workbench.default_stop_area_provider) }
    end
  end
end
