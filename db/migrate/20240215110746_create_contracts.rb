class CreateContracts < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :contracts do |t|
        t.string :name
        t.references :company
        t.references :workbench
        t.timestamps
      end

      add_reference :lines, :contract, index: true
    end
  end
end
