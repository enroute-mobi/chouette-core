class CreateEntrances < ActiveRecord::Migration[5.2]
  def change
    create_table "entrances" do |t|
      t.string "name"
      t.bigint "stop_area_id"
      t.boolean "entry", default: false
      t.boolean "exit", default: false
      t.jsonb "entrance_type", default: {}
      t.string "description"
      t.jsonb "localisation", default: {}
      t.decimal "longitude", precision: 19, scale: 16
      t.decimal "latitude", precision: 19, scale: 16
      t.string "address"
      t.string "zip_code"
      t.string "city_name"
      t.string "country"
      # t.index ["objectid"], name: "entrances_objectid_key", unique: true
      # t.index ["stop_area_provider_id"], name: "index_entrances_on_stop_area_provider_id"
      # t.index ["stop_area_id"], name: "index_entrances_on_stop_area_id"
      t.timestamps
    end
  end
end
