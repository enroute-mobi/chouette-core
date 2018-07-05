RSpec.describe AF83::SchemaCloner, type: :pg_catalog, skip: "See #7540" do
  let( :source_schema ){ "source_schema" }
  let( :target_schema ){ "target_schema" }
  let( :child_table ){ "children" }
  let( :parent_table ){ "parents" }

  subject { described_class.new source_schema, target_schema }

  context "after cloning" do
    before do
      create_schema_with_tables
      subject.clone_schema
    end

    it "table information is correctly duplicated" do
      expect(get_table_information(source_schema, child_table))
        .to eq([{"table_schema"=>"source_schema",
      "table_name"=>"children",
      "table_type"=>"BASE TABLE",
      "self_referencing_column_name"=>nil,
      "reference_generation"=>nil,
      "user_defined_type_catalog"=>nil,
      "user_defined_type_schema"=>nil,
      "user_defined_type_name"=>nil,
      "is_insertable_into"=>"YES",
      "is_typed"=>"NO",
      "commit_action"=>nil}])

      expect( get_table_information(target_schema, child_table))
        .to eq([{"table_schema"=>"target_schema",
      "table_name"=>"children",
      "table_type"=>"BASE TABLE",
      "self_referencing_column_name"=>nil,
      "reference_generation"=>nil,
      "user_defined_type_catalog"=>nil,
      "user_defined_type_schema"=>nil,
      "user_defined_type_name"=>nil,
      "is_insertable_into"=>"YES",
      "is_typed"=>"NO",
      "commit_action"=>nil}])
    end

    it "table content is the same and sequences are synchronized" do
      expect_same_content(parent_table)
      expect_same_content(child_table)

      expect_same_sequence_params("#{parent_table}_id_seq")
      expect_same_sequence_params("#{child_table}_id_seq")
    end

    it "has correctly updated default values" do
      child_table_pk_default = get_columns(target_schema, child_table)
        .find{ |col| col["column_name"] == "id" }["column_default"]
      expect( child_table_pk_default ).to eq("nextval('#{target_schema}.children_id_seq'::regclass)")
    end

    it "has the correct foreign keys" do
      expect( get_foreign_keys(target_schema, child_table) )
        .to eq([{
        "constraint_name" => "children_parents",
        "constraint_def"  => "FOREIGN KEY (parents_id) REFERENCES target_schema.parents(id)"}])
    end

    xit "it has the correct unique keys UNTESTABLE SO FAR" do
      insert source_schema, child_table, "#{parent_table}_id" => 1, some_key: 400
      insert target_schema, child_table, "#{parent_table}_id" => 1, some_key: 400
      reinsert_sql = "INSERT INTO #{source_schema}.#{child_table} (#{parent_table}_id, some_key) VALUES (1, 400)"
      expect{ execute(reinsert_sql) rescue nil}.not_to change{ execute("SELECT COUNT(*) FROM #{source_schema}.#{child_table}") }

      # expect{  insert(target_schema, child_table, "#{parent_table}_id" => 1, some_key: 400) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "inserts are independent" do
      insert source_schema, child_table, "#{parent_table}_id" => 1, some_key: 400
      insert target_schema, child_table, "#{parent_table}_id" => 1, some_key: 400
      last_source = get_content(source_schema, child_table).last
      last_target = get_content(target_schema, child_table).last

      expect( last_source ).to eq("id"=>"3", "parents_id"=>"1", "some_key"=>"400", "is_orphan"=>"f")
      expect( last_target ).to eq("id"=>"3", "parents_id"=>"1", "some_key"=>"400", "is_orphan"=>"f")
    end

  end

  def create_schema_with_tables
    execute <<-EOSQL
    DROP SCHEMA IF EXISTS #{source_schema} CASCADE;
    CREATE SCHEMA #{source_schema};

    CREATE TABLE #{source_schema}.#{parent_table} (
      id bigserial PRIMARY KEY
    );
    CREATE TABLE #{source_schema}.#{child_table} (
      id bigserial PRIMARY KEY,
    #{parent_table}_id bigint,
     some_key bigint NOT NULL,
      is_orphan boolean DEFAULT false
    );

    CREATE UNIQUE INDEX #{child_table}_some_key_idx ON #{source_schema}.#{child_table} (some_key);

    ALTER TABLE #{source_schema}.#{child_table}
      ADD CONSTRAINT #{child_table}_#{parent_table}
      FOREIGN KEY( #{parent_table}_id ) REFERENCES #{source_schema}.#{parent_table}(id);

    INSERT INTO #{source_schema}.#{parent_table} VALUES (DEFAULT);
    INSERT INTO #{source_schema}.#{parent_table} VALUES (DEFAULT);
    EOSQL
    insert source_schema, child_table, "#{parent_table}_id" => 1, some_key: 200
    insert source_schema, child_table, "#{parent_table}_id" => 2, some_key: 300, is_orphan: true
  end

end
