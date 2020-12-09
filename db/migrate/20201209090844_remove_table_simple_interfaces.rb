class RemoveTableSimpleInterfaces < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      drop_table :simple_interfaces
    end
  end

  def down
    on_public_schema_only do
      create_table "simple_interfaces", force: :cascade do |t|
        t.string "configuration_name"
        t.string "filepath"
        t.string "status"
        t.json "journal"
        t.string "type"
      end
    end
  end
end
