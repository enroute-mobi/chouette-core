# frozen_string_literal: true

RSpec.describe Export::Base, type: :model do
  subject(:export) { Export::Base.new }

  it { should belong_to(:referential) }
  it { is_expected.to belong_to(:workbench).optional }

  it { should enumerize(:status).in("aborted", "canceled", "failed", "new", "pending", "running", "successful", "warning") }

  it { should validate_presence_of(:creator) }

  it { should allow_value(fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip')).for(:file) }
  it do
    message = I18n.t('errors.messages.extension_whitelist_error', extension: '"png"', allowed_types: 'zip, csv, json')
    should_not allow_value(fixture_file_upload('sample_png.png')).for(:file).with_message(message)
  end

  describe ".purge_exports" do
    let(:workbench) { create(:workbench) }
    let(:other_workbench) { create(:workbench) }

    it "removes files from exports older than 60 days" do
      file_purgeable = Timecop.freeze(60.days.ago) do
        export = create(
          :gtfs_export,
          workbench: workbench,
          file: file_fixture('terminated_job.json').open
        )
      end

      other_file_purgeable = Timecop.freeze(60.days.ago) do
        export = create(
          :gtfs_export,
          workbench: other_workbench,
          file: file_fixture('terminated_job.json').open
        )
      end

      Export::Gtfs.new(workbench: workbench).purge_exports

      expect(file_purgeable.reload.file_url).to be_nil
      expect(other_file_purgeable.reload.file_url).not_to be_nil
    end

    it "removes exports older than 90 days" do
      old_export = Timecop.freeze(90.days.ago) do
        create(:gtfs_export, workbench: workbench)
      end

      other_old_export = Timecop.freeze(90.days.ago) do
        create(:gtfs_export, workbench: other_workbench)
      end

      expect { Export::Gtfs.new(workbench: workbench).purge_exports }.to change {
        old_export.workbench.exports.purgeable.count
      }.from(1).to(0)

      expect { Export::Gtfs.new(workbench: workbench).purge_exports }.not_to change {
        old_export.workbench.exports.purgeable.count
      }
    end

    it 'keeps files used in Publication Apis' do
      old_export = Timecop.freeze(90.days.ago) do
        # We create TWO exports
        create(:gtfs_export, workbench: workbench)
        create(:gtfs_export, workbench: workbench)
      end

      context = Chouette.create do
        publication_api
        referential :referential
        publication referential: :referential
      end
      context.publication_api.publication_api_sources.create!(
        publication: context.publication, export: old_export, key: 'foo'
      )
      context.publication_api.publication_api_sources.create!(
        publication: context.publication, export: old_export, key: 'foo2'
      )

      expect { Export::Gtfs.new(workbench: workbench).purge_exports }.to change {
        workbench.exports.count
      }.by -1
    end
  end

  describe "#destroy" do

    it "must destroy all associated Export::Messages" do
      export = create(:gtfs_export)
      create(:export_message, export: export)
      export.destroy

      expect(Export::Message.count).to eq(0)
    end
  end

  describe "#clean_exportables" do
    let(:context) do
      Chouette.create { line }
    end
    let(:line) { context.line }
    let(:export) { create(:gtfs_export) }
    before(:each) { export.exportables.create(export: export, model: line) }

    context 'when export is destroyed' do
      it 'must destroy all associated Exportables' do
        expect{ export.destroy }.to change { export.exportables.count }.from(1).to(0)
      end
    end

    context 'when export run' do
      it 'must destroy all associated Exportables' do
        expect{ export.run }.to change { export.exportables.count }.from(1).to(0)
      end
    end
  end

  context "#user_file" do

    before do
      subject.name = "Dummy Export Example"
    end

    it 'uses a parameterized version of the Export name as base name' do
      expect(subject.user_file.basename).to eq("dummy-export-example")
    end

    it 'uses the Export content_type' do
      expect(subject.user_file.content_type).to eq(subject.content_type)
    end

    it 'uses the Export file_extension' do
      expect(subject.user_file.extension).to eq(subject.send(:file_extension))
    end

  end

  context "#has_feature?" do
    subject { export.has_feature?(feature) }

    let(:export) { Export::Base.new }
    let(:feature) { "dummy"}

    let(:organisation) { Organisation.new }

    context "when a Workbench is defined" do
      before { export.organisation = organisation }
      context "when the Workbench organisation has the feature" do
        before { organisation.features << feature }
        it { is_expected.to be_truthy }
      end
      context "when the Workbench organisation hasn't the feature" do
        it { is_expected.to be_falsy }
      end
    end

    context "when only the Workgroup is defined" do
      before { export.workgroup = Workgroup.new(owner: organisation) }
      context "when the Workgroup organisation has the feature" do
        before { organisation.features << feature }
        it { is_expected.to be_truthy }
      end
      context "when the Workgroup organisation hasn't the feature" do
        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#cache_key_provider' do
    subject { export.cache_key_provider }

    let(:workgroup) { Chouette.create { workgroup }.workgroup }
    let(:export) { Export::Base.new(workgroup: workgroup) }

    context 'when cache_prefix is nil' do
      before { export.cache_prefix = nil }

      it { is_expected.to be_nil }
    end

    context "when cache_prefix is'nt nil (for example: 'dummy')" do
      before { export.cache_prefix = 'dummy' }

      it { is_expected.to an_instance_of(Export::Base::CacheKeyProvider) }

      describe 'returned CacheKeyProvider' do
        it { is_expected.to have_attributes(cache_prefix: export.cache_prefix) }

        context "when cache_version is 'version'" do
          before { allow(export).to receive(:cache_version) { 'version' } }

          it { is_expected.to have_attributes(cache_version: export.cache_version) }
        end
      end
    end
  end

  describe Export::Base::CacheKeyProvider do
    subject(:cache_key_provider) { described_class.new }

    describe '#format_key' do
      subject { cache_key_provider.send :format_key, model_cache_key }

      context 'when a model_cache_key is "model_cache_key"' do
        let(:model_cache_key) { 'model_cache_key' }

        context 'when a cache_prefix is "prefix"' do
          before { cache_key_provider.cache_prefix = 'prefix' }

          it { is_expected.to eq('prefix/model_cache_key') }

          context 'when a cache_version is "version"' do
            before { cache_key_provider.cache_version = 'version' }

            it { is_expected.to eq('prefixversion/model_cache_key') }
          end
        end
      end
    end
  end
end
