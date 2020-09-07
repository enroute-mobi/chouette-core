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

    it "returns names of all tables" do
      is_expected.to include(*table_samples)
      is_expected.to have_attributes(size: (be >= 25))
    end

  end

  describe "#usefull_table_names" do

    subject { referential_schema.usefull_table_names }

    it "returns names of tables present only in the Referential schema" do
      is_expected.not_to include(referential_schema.excluded_table_names)
      is_expected.to have_attributes(size: (be < 100))
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

  describe "#excluded_table_names" do

    subject { referential_schema.excluded_table_names }

    let(:unused_table_samples) do
      %w{aggregates api_keys calendars companies connection_links
        group_of_lines lines line_notices networks stop_areas
        clean_ups clean_up_results codes }
    end

    it "returns names of all tables used in public schema and not in the Referential schema" do
      is_expected.to include(*unused_table_samples)
      is_expected.to have_attributes(size: (be < 100))
    end

  end

  describe "#excluded_tables" do

    it "returns a Table for each excluded model table" do
      expect(referential_schema.excluded_tables.count).to eq(referential_schema.excluded_table_names.count)
      expect(referential_schema.excluded_tables.collect(&:name)).to eq(referential_schema.excluded_table_names)
    end

  end

  describe "#reduce_tables" do

    subject { referential_schema.reduce_tables }

    it "must drop excluded tables" do
      expect(referential_schema.table_names).not_to include(referential_schema.excluded_table_names)
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

    let(:model_count) { 10 }

    let(:context) do
      Chouette.create do
        referential :source do
          10.times { vehicle_journey }
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
        target.switch { Chouette::JourneyPattern.count }
      }.from(0).to(1)
    end

    it "copy all VehicleJourneys from source referential to target one" do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.switch { Chouette::VehicleJourney.count }
      }.from(0).to(model_count)
    end

    it "update primary key sequences" do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.schema.current_value("vehicle_journeys_id_seq")
      }.from(1).to(model_count)
    end


  end

end
