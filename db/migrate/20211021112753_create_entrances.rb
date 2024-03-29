class CreateEntrances < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table "entrances" do |t|
        t.string "objectid", null: false
        t.string "name"
        t.string "short_name"
        t.references "stop_area"
        t.references "stop_area_provider"
        t.references "stop_area_referential"
        t.boolean "entry_flag", default: false
        t.boolean "exit_flag", default: false
        t.string "entrance_type"
        t.string "description"
        t.st_point :position, geographic: true
        t.string "address"
        t.string "zip_code"
        t.string "city_name"
        t.string "country"
        t.index ["objectid"], unique: true
        t.timestamps
      end
    end
  end
end