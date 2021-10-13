RSpec.describe Query::Import do
  let(:query) { Query::Import.new(Import::Base.all) }

  let(:context) { Chouette.create { workbench } }
  let(:workbench) { context.workbench }

  let(:import) do
    workbench.imports.create!(name: "test", creator: "test", file: open_fixture('google-sample-feed.zip'))
  end

  describe "#statuses" do
    Import::Workbench.status.values.each do |status|
      context "when the queried status is #{status}" do
        subject { query.statuses(status).scope }

        it "includes imports with this status" do
          import.update_column :status, status
          is_expected.to include(import)
        end

        it "excludes imports without this status" do
          other_status = (Import::Workbench.status.values - [ status ]).first

          import.update_column :status, other_status
          is_expected.to_not include(import)
        end
      end
    end
  end

  describe "#workbench" do
    let(:context) do
      Chouette.create do
        workbench :first
        workbench :other
      end
    end

    let(:workbench) { context.workbench(:first) }
    let(:other_workbench) { context.workbench(:other) }

    subject { query.workbenches(workbench).scope }

    it "includes imports in the queried workbench" do
      is_expected.to include(import)
    end

    it "exclude imports from other workbenchs" do
      import.update_column :workbench_id, other_workbench.id
      is_expected.to_not include(import)
    end
  end

  describe "#text" do
    subject { query.text(queried_text).scope }

    context "when Import is named 'Test Import'" do
      before { import.update_column :name, 'Test Import' }

      context "when queried text is 'Test'" do
        let(:queried_text) { 'Test' }
        it("includes the import") { is_expected.to include(import) }
      end

      context "when queried text is 'test'" do
        let(:queried_text) { 'test' }
        it("includes the import") { is_expected.to include(import) }
      end

      context "when queried text is 'import'" do
        let(:queried_text) { 'import' }
        it("includes the import") { is_expected.to include(import) }
      end

      context "when queried text is 'test import'" do
        let(:queried_text) { 'test import' }
        it("includes the import") { is_expected.to include(import) }
      end

      context "when queried text is 'Dummy'" do
        let(:queried_text) { 'Dummy' }
        it("excludes the import") { is_expected.to_not include(import) }
      end
    end
  end

end
