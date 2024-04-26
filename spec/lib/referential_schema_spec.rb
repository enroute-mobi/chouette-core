RSpec.describe ReferentialSchema do
  let(:context) { Chouette.create { referential } }
  let(:referential) { context.referential }
  let(:referential_schema) { referential.schema }

  describe '#table_names' do
    subject { referential_schema.table_names }

    let(:table_samples) do
      %w[routes stop_points
         journey_patterns journey_patterns_stop_points
         ar_internal_metadata schema_migrations]
    end

    it 'returns names of all tables' do
      is_expected.to include(*table_samples)
      is_expected.to have_attributes(size: (be >= 17))
    end
  end

  describe '#table_names_with_schema' do
    subject { referential_schema.table_names_with_schema }

    context 'when schema name is "test"' do
      let(:referential_schema) { ReferentialSchema.new('test') }

      context 'and table_names is [routes, journey_patterns]' do
        before { allow(referential_schema).to receive(:table_names).and_return(%w[routes journey_patterns]) }

        it { is_expected.to contain_exactly('"test".routes', '"test".journey_patterns') }
      end
    end
  end

  describe '#analyse' do 
    subject { referential_schema.analyse }

    it 'performs an ANALYSE for each table' do
      allow(referential_schema.connection).to receive(:execute).and_call_original

      referential_schema.table_names_with_schema.each do |table_name|
        expect(referential_schema.connection).to receive(:execute).with("ANALYZE #{table_name}").and_call_original
      end

      subject
    end
  end

  describe '#tables' do
    subject { referential_schema.tables }

    it 'returns a Table for each model table' do
      table_name = 'dummy'
      allow(referential_schema).to receive(:table_names).and_return([table_name])

      is_expected.to eq([ReferentialSchema::Table.new(referential_schema, table_name)])
    end
  end

  describe '.apartment_excluded_table_names' do
    subject { ReferentialSchema.apartment_excluded_table_names }

    it 'returns names of all tables used by Apartment excluded models' do
      allow(Apartment).to receive(:excluded_models).and_return(%w[Chouette::StopArea Chouette::Line])
      is_expected.to eq(%w[stop_areas lines])
    end

    self::APARTMENT_EXCLUDED_TABLE_SAMPLES =
      %w[aggregates api_keys calendars companies connection_links
         group_of_lines lines line_notices networks stop_areas
         clean_ups clean_up_results codes].freeze

    it "returns table names like #{self::APARTMENT_EXCLUDED_TABLE_SAMPLES.to_sentence.truncate(80)}" do
      is_expected.to include(*self.class::APARTMENT_EXCLUDED_TABLE_SAMPLES)
    end
  end

  describe '.excluded_table_names' do
    subject { ReferentialSchema.excluded_table_names }

    it 'returns all tables used by Apartment excluded models (apartment_excluded_table_names)' do
      is_expected.to include(*ReferentialSchema.apartment_excluded_table_names)
    end
  end

  describe '#excluded_tables' do
    subject { referential_schema.excluded_tables }

    it 'returns a Table for each excluded model table' do
      expected_tables = referential_schema.excluded_table_names.map do |name|
        an_object_having_attributes name: name.to_sym
      end
      is_expected.to match_array(expected_tables)
    end
  end

  describe '#reduce_tables' do
    let(:referential_schema) { ReferentialSchema.new 'test_reduce_tables' }
    before { referential_schema.create skip_reduce_tables: true }

    let(:reduced_tables) { referential_schema.excluded_table_names }

    it 'must drop excluded tables' do
      expect do
        referential_schema.reduce_tables
      end.to change { referential_schema.table_names }
        .from(an_array_including(*reduced_tables))
        .to(an_array_excluding(*reduced_tables))
    end
  end

  describe '#table' do
    it 'returns the Table instance with the given name' do
      expect(referential_schema.table('routes')).to eq(ReferentialSchema::Table.new(referential_schema, 'routes'))
    end

    it "returns nil when the table doesn't exist" do
      expect(referential_schema.table('dummy')).to be_nil
    end
  end

  describe '#associated_table' do
    let(:table) { double name: 'routes' }

    it 'returns the table in the referential schema with the same name than the given one' do
      expect(referential_schema.associated_table(table)).to eq(ReferentialSchema::Table.new(referential_schema,
                                                                                            table.name))
    end
  end

  describe '#clone_to' do
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

    it 'copy all Routes from source referential to target' do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.switch { Chouette::Route.count }
      }.from(0).to(1)
    end

    it 'copy all JourneyPatterns from source referential to target' do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.switch { Chouette::JourneyPattern.count }
      }.from(0).to(1)
    end

    it 'copy all VehicleJourneys from source referential to target' do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.switch { Chouette::VehicleJourney.count }
      }.from(0).to(model_count)
    end

    it 'update primary key sequences' do
      expect { referential.schema.clone_to(target.schema) }.to change {
        target.schema.current_value('vehicle_journeys_id_seq')
      }.from(1).to(model_count)
    end

    it 'allows target table to create new records after the copy' do
      referential.schema.clone_to(target.schema)
      target.switch { Chouette::VehicleJourney.create!(journey_pattern: context.journey_pattern, route: context.route) }
    end
  end

  describe ReferentialSchema::Table do
    let(:context) do
      Chouette.create do
        referential do
          3.times { vehicle_journey }
        end
      end
    end

    let(:referential) { context.referential }
    let(:table) { referential.schema.table('vehicle_journeys') }

    def truncate_table
      referential.switch { referential.vehicle_journeys.delete_all }
    end

    describe '#empty?' do
      it 'returns false when the table has records, true if the table is empty' do
        expect { truncate_table }.to change(table, :empty?).from(false).to(true)
      end
    end

    describe '#count' do
      it 'returns the number of records in the table' do
        expect { truncate_table }.to change(table, :count).from(3).to(0)
      end
    end

    describe 'columns' do
      it 'returns an array with ordered column names for the table' do
        expected = %w[
          id route_id journey_pattern_id company_id objectid
          object_version comment transport_mode published_journey_name
          published_journey_identifier facility vehicle_type_identifier
          number mobility_restricted_suitability flexible_service
          journey_category created_at updated_at checksum checksum_source
          data_source_ref custom_field_values metadata
          ignored_routing_contraint_zone_ids ignored_stop_area_routing_constraint_ids
          line_notice_ids service_facility_set_ids
        ]

        expect(table.columns).to eq(expected)
      end
    end
  end
end
