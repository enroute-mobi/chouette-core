class CreateControls < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :control_lists do |t|
        t.references :workbench
        t.string :name
        t.text :comments
        t.timestamps
      end
      create_table :controls do |t|
        t.string :type, null: false
        t.references :control_list
        t.integer :position, null: false

        t.string :name
        t.text :comments
        t.string :criticity
        t.string :code
        t.jsonb :options, default: {}
        t.timestamps

        t.index [:control_list_id, :position], unique: true
      end
    end
  end
end
