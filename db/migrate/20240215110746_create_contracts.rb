class CreateContracts < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :contracts do |t|
        t.string :name
        t.bigint :line_ids, array: true
        t.references :company
        t.references :workbench
        t.timestamps
      end
    end
  end
end
