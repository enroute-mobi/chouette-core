class AddNameToMerges < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      change_table :merges do |t|
        t.string :name
      end
    end
  end
end
