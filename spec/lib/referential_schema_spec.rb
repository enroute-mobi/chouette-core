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
      is_expected.to have_attributes(size: (be >= 20))
    end

  end

  describe "#tables" do

    subject { referential_schema.tables }

    it "returns a Table for each model table" do
      table_name = 'dummy'
      allow(referential_schema).to receive(:table_names).and_return([table_name])

      is_expected.to eq([ReferentialSchema::Table.new(referential_schema, table_name)])
    end

  end

  describe ".apartment_excluded_table_names" do

    subject { ReferentialSchema.apartment_excluded_table_names }

    it "returns names of all tables used by Apartment excluded models" do
      allow(Apartment).to receive(:excluded_models).and_return(%w{Chouette::StopArea Chouette::Line})
      is_expected.to eq(%w{stop_areas lines})
    end

    APARTMENT_EXCLUDED_TABLE_SAMPLES =
      %w{aggregates api_keys calendars companies connection_links
        group_of_lines lines line_notices networks stop_areas
        clean_ups clean_up_results codes}

    it "returns table names like #{APARTMENT_EXCLUDED_TABLE_SAMPLES.to_sentence.truncate(80)}" do
      is_expected.to include(*APARTMENT_EXCLUDED_TABLE_SAMPLES)
    end

  end

  describe ".excluded_table_names" do

    subject { ReferentialSchema.excluded_table_names }

    it "returns all tables used by Apartment excluded models (apartment_excluded_table_names)" do
      is_expected.to include(*ReferentialSchema.apartment_excluded_table_names)
    end

  end

  describe "#excluded_tables" do

    subject { referential_schema.excluded_tables }

    it "returns a Table for each excluded model table" do
      expect(subject.map(&:name)).to eq(referential_schema.excluded_table_names)
    end

  end

  describe "#reduce_tables" do

    let(:referential_schema) { ReferentialSchema.new 'test_reduce_tables' }
    before { referential_schema.create skip_reduce_tables: true }

    let(:reduced_tables) { referential_schema.excluded_table_names }

    it "must drop excluded tables" do
      expect {
        referential_schema.reduce_tables
      }.to change { referential_schema.table_names }.
             from(an_array_including(*reduced_tables)).
             to(an_array_excluding(*reduced_tables))
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
