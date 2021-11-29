class CreateMacros < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :macro_lists do |t|
        t.references :workgroup
        t.text :name
        t.text :comments
        t.timestamps
      end
      create_table :macros do |t|
        t.string :type, null: false
        t.references :macro_list
        t.integer :position, null: false

        t.text :name
        t.text :comments
        t.jsonb :options, default: {}
        t.timestamps

        t.index [:macro_list_id, :position], unique: true
      end
    end
  end
end
