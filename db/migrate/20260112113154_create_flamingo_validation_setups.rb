# frozen_string_literal: true

class CreateFlamingoValidationSetups < ActiveRecord::Migration[7.2]
  def up # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      create_table :flamingo_validation_setups do |t|
        t.references :workgroup, null: false, index: false, foreign_key: true
        t.string :name, null: false
        t.string :ruleset, null: false
        t.boolean :include_schema, null: false, default: false
        t.string :schema_version, null: false
        t.string :token, null: false
        t.timestamps null: false
        t.index %i[workgroup_id name], unique: true
      end

      change_table :flamingo_validations do |t|
        t.references :setup, null: false, foreign_key: { to_table: :flamingo_validation_setups }
        t.remove :processing_rule_id
      end

      change_table :processing_rules do |t|
        t.remove :processing_setup
      end
    end
  end

  def down
    on_public_schema_only do
      drop_table :flamingo_validation_setups

      change_table :flamingo_validations do |t|
        t.remove :setup_id
        t.references :processing_rule, foreign_key: { to_table: :processing_rules }, null: false
      end

      change_table :processing_rules do |t|
        t.jsonb :processing_setup
      end
    end
  end
end
