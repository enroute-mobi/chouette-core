# frozen_string_literal: true

RSpec.describe Import::Base, type: :model do
  subject(:import) { Import::Base.new }

  it { is_expected.to belong_to(:referential).optional }
  it { is_expected.to belong_to(:workbench).required }
  it { is_expected.to belong_to(:parent).optional }

  it {
    should enumerize(:status).in('aborted', 'canceled', 'failed', 'new', 'pending', 'running', 'successful', 'warning')
  }

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
      subject.file = fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip')
    end

    it 'uses a parameterized version of the Import name as base name' do
      expect(subject.user_file.basename).to eq('dummy-import-example')
    end

    it 'uses the Import content_type' do
      expect(subject.user_file.content_type).to eq('application/zip')
    end

    it 'uses the Import file_extension' do
      expect(subject.user_file.extension).to eq('zip')
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

  describe '#workgroup_control_list_run' do
    subject { import.workgroup_control_list_run }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench do
            control_list :control_list, shared: true
          end
          workgroup_processing_rule control_list: :control_list, operation_step: 'after_import'
        end
      end
    end
    let(:workbench) { context.workbench }
    let(:control_list) { context.control_list(:control_list) }

    let(:import) do
      Import::Gtfs.create!(
        workbench: workbench,
        local_file: open_fixture('google-sample-feed.zip'),
        creator: 'test',
        name: 'test'
      ).tap(&:import)
    end
    let(:control_list_run) do
      import.processings.find { |p| p.processed.try(:original_control_list) == control_list }.processed
    end

    it { is_expected.to have_attributes(processed: control_list_run) }

    context 'when processed is destroyed' do
      before { control_list_run.destroy }
      it { is_expected.to be_nil }
    end
  end

  describe '#workbench_macro_list_run' do
    subject { import.workbench_macro_list_run }

    let(:context) do
      Chouette.create do
        workbench do
          macro_list :macro_list
          workbench_processing_rule macro_list: :macro_list, operation_step: 'after_import'
        end
      end
    end
    let(:workbench) { context.workbench }
    let(:macro_list) { context.macro_list(:macro_list) }

    let(:import) do
      Import::Gtfs.create!(
        workbench: workbench,
        local_file: open_fixture('google-sample-feed.zip'),
        creator: 'test',
        name: 'test'
      ).tap(&:import)
    end
    let(:macro_list_run) do
      import.processings.find { |p| p.processed.try(:original_macro_list) == macro_list }.processed
    end

    it { is_expected.to have_attributes(processed: macro_list_run) }

    context 'when processed is destroyed' do
      before { macro_list_run.destroy }
      it { is_expected.to be_nil }
    end
  end

  describe '#workbench_control_list_run' do
    subject { import.workbench_control_list_run }

    let(:context) do
      Chouette.create do
        workbench do
          control_list :control_list, shared: true
          workbench_processing_rule control_list: :control_list, operation_step: 'after_import'
        end
      end
    end
    let(:workbench) { context.workbench }
    let(:control_list) { context.control_list(:control_list) }

    let(:import) do
      Import::Gtfs.create!(
        workbench: workbench,
        local_file: open_fixture('google-sample-feed.zip'),
        creator: 'test',
        name: 'test'
      ).tap(&:import)
    end
    let(:control_list_run) do
      import.processings.find { |p| p.processed.try(:original_control_list) == control_list }.processed
    end

    it { is_expected.to have_attributes(processed: control_list_run) }

    context 'when processed is destroyed' do
      before { control_list_run.destroy }
      it { is_expected.to be_nil }
    end
  end
end
