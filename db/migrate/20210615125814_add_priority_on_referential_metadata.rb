class AddPriorityOnReferentialMetadata < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :referential_metadata do |t|
        t.integer :priority
      end
    end
  end
end
