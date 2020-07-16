class CreateShapes < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      create_table :shape_referentials do |t|
        t.timestamps
      end

      change_table :workgroups do |t|
        t.belongs_to :shape_referential
      end

      Workgroup.find_each do |workgroup|
        workgroup.create_shape_referential
        workgroup.save
      end

      change_column_null :workgroups, :shape_referential_id, false

      create_table :shape_providers do |t|
        t.string :short_name, null: false
        t.belongs_to :workbench, null: false
        t.belongs_to :shape_referential, null: false

        t.timestamps
      end

      Workbench.find_each do |workbench|
        workbench.create_default_shape_provider
      end

      execute 'CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA shared_extensions;'

      create_table :shapes do |t|
        t.string :name
        t.line_string :geometry, srid: 4326
        t.uuid :uuid, default: "gen_random_uuid()", null: false
        t.belongs_to :shape_referential, null: false
        t.belongs_to :shape_provider, null: false

        t.timestamps
      end
    end
  end

  def down
    remove_column :workgroups, :shape_referential_id if column_exists? :workgroups, :shape_referential_id
    drop_table :shapes if table_exists? :shapes
    drop_table :shape_providers if table_exists? :shape_providers
    drop_table :shape_referentials if table_exists? :shape_referentials

    # Drop the extension is difficult because the migrations are executed several times by Apartment
    # execute 'DROP EXTENSION IF EXISTS pgcrypto;'
  end

end
