# frozen_string_literal: true

RSpec.describe Referential::Schema do
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
      let(:referential_schema) { Referential::Schema.new('test') }

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

    before { referential_schema.reset_caches }

    it 'returns a Table for each model table' do
      table_name = 'dummy'
      allow(referential_schema).to receive(:table_names).and_return([table_name])

      is_expected.to eq([Referential::Schema::Table.new(referential_schema, table_name)])
    end
  end

  describe '.apartment_excluded_table_names' do
    subject { Referential::Schema.apartment_excluded_table_names }

    it 'returns names of all tables used by Apartment excluded models' do
      allow(Apartment).to receive(:excluded_models).and_return(%w[Chouette::StopArea Chouette::Line])
      is_expected.to eq(%w[stop_areas lines])
    end

    self::APARTMENT_EXCLUDED_TABLE_SAMPLES =
      %w[aggregates api_keys calendars companies connection_links
        lines line_notices networks stop_areas
         clean_ups clean_up_results codes].freeze

    it "returns table names like #{self::APARTMENT_EXCLUDED_TABLE_SAMPLES.to_sentence.truncate(80)}" do
      is_expected.to include(*self.class::APARTMENT_EXCLUDED_TABLE_SAMPLES)
    end
  end

  describe '.excluded_table_names' do
    subject { Referential::Schema.excluded_table_names }

    it 'returns all tables used by Apartment excluded models (apartment_excluded_table_names)' do
      is_expected.to include(*Referential::Schema.apartment_excluded_table_names)
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
    let(:referential_schema) { Referential::Schema.new 'test_reduce_tables' }
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
      expect(referential_schema.table('routes')).to eq(Referential::Schema::Table.new(referential_schema, 'routes'))
    end

    it "returns nil when the table doesn't exist" do
      expect(referential_schema.table('dummy')).to be_nil
    end
  end

  describe '#associated_table' do
    let(:table) { double name: 'routes' }

    it 'returns the table in the referential schema with the same name than the given one' do
      expect(referential_schema.associated_table(table)).to eq(Referential::Schema::Table.new(referential_schema,
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

  describe '#dump', truncation: true do
    subject { referential_schema.dump(file) }

    let(:file) { Tempfile.new }
    let(:file_content) { Zlib::GzipReader.open(file.path).read }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do
        code_space short_name: 'some_code_space'
        line :line

        referential lines: %i[line] do
          footnote :footnote, code: 'some_footnote'

          time_table :time_table,
                     comment: 'some_time_table',
                     codes: { 'some_code_space' => 'time_table_code' },
                     dates_included: [Date.parse('2024-12-13')],
                     dates_excluded: [Date.parse('2025-06-23')],
                     periods: [Period.parse('2030-01-07..2030-01-20')]

          route name: 'some_route', codes: { 'some_code_space' => 'route_code' }, with_stops: false, line: :line do
            stop_point metadata: { name: 'stop_point1' }
            stop_point metadata: { name: 'stop_point2' }
            stop_point metadata: { name: 'stop_point3' }

            journey_pattern name: 'some_journey_pattern', codes: { 'some_code_space' => 'journey_pattern_code' } do
              vehicle_journey published_journey_name: 'some_vehicle_journey',
                              codes: { 'some_code_space' => 'vehicle_journey_code' },
                              footnotes: %i[footnote],
                              time_tables: %i[time_table]
            end

            routing_constraint_zone name: 'some_routing_constraint_zone'
          end
        end
      end.tap do |context|
        context.referential.switch do
          ServiceCount.create!(
            line_id: context.line(:line).id,
            route_id: context.route.id,
            journey_pattern_id: context.journey_pattern.id,
            date: '2025-02-04'
          )
        end
      end
    end

    before { subject }
    after(:each) { file.close! }

    it 'creates schema' do
      expect(file_content).to include("CREATE SCHEMA \"#{referential.slug}\"")
    end

    it 'creates schema migrations table' do
      expect(file_content).to include("CREATE TABLE \"#{referential.slug}\".schema_migrations")
    end

    describe 'tables creation' do
      [
        ['referential_codes', true],
        ['footnotes', true],
        ['time_tables', true],
        ['time_table_dates', true],
        ['time_table_periods', true],
        ['routes', true],
        ['stop_points', true],
        ['journey_patterns', true],
        ['journey_patterns_stop_points', false],
        ['vehicle_journeys', true],
        ['vehicle_journey_at_stops', true],
        ['footnotes_vehicle_journeys', false],
        ['time_tables_vehicle_journeys', false],
        ['routing_constraint_zones', true],
        ['service_counts', true]
      ].each do |table_name, has_id|
        it { expect(file_content).to include("CREATE TABLE \"#{referential.slug}\".#{table_name}") }
        if has_id
          it { expect(file_content).to include("CREATE SEQUENCE \"#{referential.slug}\".#{table_name}_id_seq") }
          it { expect(file_content).to include("ALTER SEQUENCE \"#{referential.slug}\".#{table_name}_id_seq OWNED BY \"#{referential.slug}\".#{table_name}.id") } # rubocop:disable Layout/LineLength
          it { expect(file_content).to include("ALTER TABLE ONLY \"#{referential.slug}\".#{table_name} ALTER COLUMN id SET DEFAULT nextval('\"#{referential.slug}\".#{table_name}_id_seq'::regclass)") } # rubocop:disable Layout/LineLength
        end
      end
    end

    describe 'data' do
      it 'contains current migration version' do
        expect(file_content).to include(ActiveRecord::Migrator.current_version.to_s)
      end

      %w[
        some_footnote
        some_time_table
        time_table_code
        2024-12-13
        2025-06-23
        2030-01-07
        some_route
        route_code
        stop_point1
        stop_point2
        stop_point3
        some_journey_pattern
        journey_pattern_code
        some_vehicle_journey
        vehicle_journey_code
        some_routing_constraint_zone
        2025-02-04
      ].each do |data|
        it { expect(file_content).to include(data) }
      end
    end
  end

  describe '#destroy!' do
    subject { referential_schema.destroy! }

    let(:context) do
      Chouette.create do
        line_notice :line_notice
        referential do
          vehicle_journey line_notices: %i[line_notice]
        end
      end
    end
    let(:line_notice) { context.line_notice(:line_notice) }

    it 'destroys schema' do
      expect { subject }.to change { ::ActiveRecord::Base.connection.schema_names }.from(include(referential.slug))
                                                                                   .to(not_include(referential.slug))
    end
  end
end

RSpec.describe Referential::Schema::Table do
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
        id route_id journey_pattern_id company_id objectid published_journey_identifier
        object_version transport_mode published_journey_name custom_field_values
        created_at updated_at checksum checksum_source data_source_ref metadata
        line_notice_ids accessibility_assessment_id service_facility_set_ids
      ]

      expect(table.columns).to match_array(expected)
    end
  end
end
