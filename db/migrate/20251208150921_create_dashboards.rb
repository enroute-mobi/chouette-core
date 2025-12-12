class CreateDashboards < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      create_table :dashboards do |t|
        t.references :workbench, null: false, foreign_key: true
        t.string :name, null: false
        t.text :description

        t.timestamps
      end
    end
  end
end
