class CreatePointOfInterest < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :point_of_interest_categories do |t|
        t.references :shape_referential, null: false
        t.references :shape_provider, null: false
        t.references :parent, foreign_key: { to_table: :point_of_interest_categories }
        t.string :name, null: false

        t.timestamps
      end

      create_table :point_of_interest_hours do |t|
        t.references :point_of_interest, null: false
        t.time :opening_time_of_day, null: false, default: "2000-01-01 00:00:00"
        t.time :closing_time_of_day, null: false, default: "2000-01-01 00:00:00"
        t.bit :week_days, limit: 7, default: "1111111"

        t.timestamps
      end

      create_table :point_of_interests do |t|
        t.references :shape_referential, null: false
        t.references :shape_provider, null: false
        t.references :point_of_interest_category, null: false
        t.string :name, null: false
        t.string :url
        t.st_point :position, geographic: true
        t.string :address
        t.string :zip_code
        t.string :city_name
        t.string :country
        t.string :email
        t.string :phone
        t.timestamps

      end
    end
  end
end
