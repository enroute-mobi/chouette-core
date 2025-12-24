class CreateWidgets < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      create_table :widgets do |t|
        t.string :name
        t.string :widget_type
        t.jsonb :options, default: {}
        t.references :dashboard, null: false, foreign_key: true

        t.timestamps
      end
    end
  end
end
