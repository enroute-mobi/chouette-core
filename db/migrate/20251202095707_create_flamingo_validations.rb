# frozen_string_literal: true

class CreateFlamingoValidations < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      create_table :flamingo_validations do |t|
        t.references :workbench, foreign_key: true, null: false
        t.references :processing_rule, foreign_key: { to_table: :processing_rules }, null: false
        t.references :operation, polymorphic: true, null: false
        t.string :status, null: false
        t.string :user_status, null: false
        t.string :error_uuid
        t.datetime :started_at
        t.datetime :ended_at
        t.string :creator, null: false
        t.timestamps null: false
        t.string :validation_id
        t.string :validation_report_url
      end

      change_table :processing_rules do |t|
        t.jsonb :processing_setup
      end
    end
  end
end
