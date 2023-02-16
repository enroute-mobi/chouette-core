# frozen_string_literal: true

class CreateFare < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :fare_referentials do |t| # rubocop:disable Style/SymbolProc
        t.timestamps
      end

      change_table :workgroups do |t|
        t.references :fare_referential
      end

      reversible do |direction|
        direction.up do
          Workgroup.reset_column_information
          Workgroup.find_each do |workgroup|
            workgroup.create_fare_referential
            workgroup.update_column :fare_referential_id, workgroup.fare_referential.id # rubocop:disable Rails/SkipsModelValidations
          end
        end
      end

      change_column_null :workgroups, :fare_referential_id, false

      create_table :fare_providers do |t|
        t.string :short_name
        t.references :workbench
        t.references :fare_referential

        t.timestamps
      end

      reversible do |direction|
        direction.up do
          Workbench.find_each do |workbench|
            workbench.create_default_fare_provider
            workbench.save!
          end
        end
      end

      create_table :fare_zones do |t|
        t.uuid 'uuid', default: -> { 'gen_random_uuid()' }, null: false
        t.references :fare_provider
        t.string :name

        t.timestamps
      end

      create_table :fare_stop_areas_zones do |t| # rubocop:disable Rails/CreateTableWithTimestamps
        t.references :fare_zone
        t.references :stop_area
      end

      create_table :fare_products do |t|
        t.uuid 'uuid', default: -> { 'gen_random_uuid()' }, null: false
        t.references :fare_provider

        t.string :name
        t.references :company
        t.integer :price_cents

        t.timestamps
      end

      create_table :fare_validities do |t|
        t.uuid 'uuid', default: -> { 'gen_random_uuid()' }, null: false
        t.references :fare_provider

        t.string :name
        t.jsonb :expression

        t.timestamps
      end

      create_table :fare_products_validities do |t| # rubocop:disable Rails/CreateTableWithTimestamps
        t.references :fare_product
        t.references :fare_validity
      end
    end
  end
end
