RSpec.describe Query::Export do
  let(:query) { Query::Export.new(Export::Base.all) }

  let(:context) {
    Chouette.create do
      workgroup export_types: ['Export::Gtfs'] do
        workbench do
          referential
        end
      end
    end
  }

  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  let(:export) do
    workbench.exports.create!(name: "Test", creator: 'test', type: "Export::Gtfs", referential: referential, workgroup: referential.workgroup)
  end

  describe "#statuses" do
    Export::Base.status.values.each do |status|
      context "when the queried status is #{status}" do
        subject { query.statuses(status).scope }

        it "includes exports with this status" do
          export.update_column :status, status
          is_expected.to include(export)
        end

        it "excludes exports without this status" do
          other_status = (Export::Base.status.values - [ status ]).first

          export.update_column :status, other_status
          is_expected.to_not include(export)
        end
      end
    end
  end

  describe "#workbench" do
    let(:context) do
      Chouette.create do
        workbench :first do
          referential
        end
        workbench :other
      end
    end

    let(:workbench) { context.workbench(:first) }
    let(:other_workbench) { context.workbench(:other) }

    subject { query.workbenches(workbench).scope }

    it "includes exports in the queried workbench" do
      is_expected.to include(export)
    end

    it "exclude exports from other workbenchs" do
      export.update_column :workbench_id, other_workbench.id
      is_expected.to_not include(export)
    end
  end

  describe "#text" do
    subject { query.text(queried_text).scope }

    context "when export is named 'Test export'" do
      before { export.update_column :name, 'Test export' }

      context "when queried text is 'Test'" do
        let(:queried_text) { 'Test' }
        it("includes the export") { is_expected.to include(export) }
      end

      context "when queried text is 'test'" do
        let(:queried_text) { 'test' }
        it("includes the export") { is_expected.to include(export) }
      end

      context "when queried text is 'export'" do
        let(:queried_text) { 'export' }
        it("includes the export") { is_expected.to include(export) }
      end

      context "when queried text is 'test export'" do
        let(:queried_text) { 'test export' }
        it("includes the export") { is_expected.to include(export) }
      end

      context "when queried text is 'Dummy'" do
        let(:queried_text) { 'Dummy' }
        it("excludes the export") { is_expected.to_not include(export) }
      end
    end
  end

end
