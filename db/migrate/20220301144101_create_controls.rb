class CreateControls < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :control_lists do |t|
        t.references :workbench
        t.string :name, null: false
        t.text :comments
        t.timestamps
      end
      create_table :control_list_runs do |t|
        t.references :workbench
        t.string :name, null: false
        t.references :original_control_list
        t.references :referential

        # Operation
        t.string :status
        t.string :error_uuid
        t.string :creator
        t.datetime :started_at
        t.datetime :ended_at

        t.timestamps
      end

      create_table :control_contexts do |t|
        t.references :control_list

        t.string :name
        t.string :type, null: false
        t.jsonb :options, default: {}
        t.text :comments

        t.timestamps
      end
      create_table :control_context_runs do |t|
        t.references :control_list_run

        t.string :name
        t.string :type, null: false
        t.jsonb :options, default: {}
        t.text :comments

        t.timestamps
      end

      create_table :controls do |t|
        t.string :type, null: false
        t.references :control_list
        t.references :control_context, foreign_key: true
        t.integer :position, null: false

        t.string :name
        t.text :comments
        t.string :criticity, null: false
        t.string :code
        t.jsonb :options, default: {}
        t.timestamps

        t.index [:control_list_id, :control_context_id, :position], unique: true, name: "index_controls_position"
      end

      create_table :control_runs do |t|
        t.string :type, null: false
        t.references :control_list_run
        t.references :control_context_run, foreign_key: true
        t.integer :position, null: false

        t.text :name
        t.text :comments
        t.string :criticity, null: false
        t.string :code
        t.jsonb :options, default: {}
        t.timestamps

        t.index [:control_list_run_id, :control_context_run_id, :position], unique: true, name: "index_control_runs_position"
      end

      create_table :control_messages do |t|
        t.references :source, polymorphic: true
        t.references :control_run

        t.string :message_key, null: false
        t.string :criticity, null: false
        t.jsonb :message_attributes, default: {}
        t.timestamps
      end
    end
  end
end
