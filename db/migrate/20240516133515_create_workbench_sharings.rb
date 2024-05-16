# frozen_string_literal: true

class CreateWorkbenchSharings < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      create_table :workbench_sharings do |t|
        t.string :name, null: false
        t.references :workbench, null: false, index: true, foreign_key: true
        t.string :recipient_type, null: false
        t.bigint :recipient_id
        t.string :invitation_code, index: true
        t.timestamps null: false

        t.index %i[recipient_type recipient_id workbench_id],
                name: 'index_workbench_sharings_uq_on_recipient_and_workbench',
                unique: true,
                where: 'recipient_type IS NOT NULL AND recipient_id IS NOT NULL'
      end
    end
  end
end
