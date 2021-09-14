RSpec.describe Export::Ara do
  describe "a whole export" do
    let(:context) do
      Chouette.create do
        time_table :default
        vehicle_journey time_tables: [:default]
      end
    end

    subject(:export) do
      Export::Ara.create! workbench: context.workbench,
                          workgroup: context.workgroup,
                          referential: context.referential,
                          name: "Test",
                          creator: "test"
    end

    before do
      allow(export).to receive(:upload_file) do |file|
        export.file = file
      end
      export.export
      export.reload
    end

    it { is_expected.to be_successful }

    describe "file" do
      # TODO Use Ara::File to read the file
      subject { export.file.read.split("\n") }

      it { is_expected.to have_attributes(size: 18) }
    end
  end
end
