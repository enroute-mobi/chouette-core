RSpec.describe ReferentialSchema do

  let(:context) { Chouette.create { referential } }
  let(:referential) { context.referential }
  let(:referential_schema) { referential.schema }

  describe "#table_names" do

    subject { referential_schema.table_names }

    let(:table_samples) do
      %w{routes stop_points
         journey_patterns journey_patterns_stop_points
         ar_internal_metadata schema_migrations}
    end

    it "returns the names of all tables present in the Referential schema" do
      is_expected.to include(*table_samples)
      is_expected.to have_attributes(size: (be >= 90))
    end

  end

  describe "#tables" do

    subject { referential_schema.tables }

    it "returns a Table for each model table" do
      table_name = 'dummy'
      allow(referential_schema).to receive(:table_names).and_return([table_name])

      is_expected.to eq([ReferentialSchema::Table.new(referential_schema, table_name)])
    end

    it "ignores Rails tables (as ar_internal_metadata schema_migrations)" do
      rails_tables = %w{ar_internal_metadata schema_migrations}
      allow(referential_schema).to receive(:table_names).and_return(rails_tables)

      is_expected.to be_empty
    end

  end

  describe "#table" do

    it "returns the Table instance with the given name" do
      expect(referential_schema.table("routes")).to eq(ReferentialSchema::Table.new(referential_schema, "routes"))
    end

    it "returns nil when the table doesn't exist" do
      expect(referential_schema.table("dummy")).to be_nil
    end

  end

  describe "#associated_table" do

    let(:table) { double name: 'routes' }

    it "returns the table in the referential schema with the same name than the given one" do
      expect(referential_schema.associated_table(table)).to eq(ReferentialSchema::Table.new(referential_schema, table.name))
    end

  end

  describe "#clone_to" do

    let(:context) do
      Chouette.create do
        referential :source do
          vehicle_journey
        end
        referential :target
      end
    end

    let(:referential) { context.referential :source }
    let(:vehicle_journey) { context.vehicle_journey }
    let(:target) { context.referential :target }

    it "copy all Routes from source referential to target one" do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.switch { Chouette::Route.count }
      }.from(0).to(1)
    end

    it "copy all JourneyPatterns from source referential to target one" do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.switch { Chouette::Route.count }
      }.from(0).to(1)
    end

    it "copy all VehicleJourneys from source referential to target one" do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.switch { Chouette::VehicleJourney.count }
      }.from(0).to(1)
    end


  end

end
