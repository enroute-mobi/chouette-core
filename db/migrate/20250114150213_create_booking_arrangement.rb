class CreateBookingArrangement < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :booking_arrangements do |t|
        t.uuid :uuid, default: -> { "gen_random_uuid()" }, null: false
        t.string :name, null: false
        t.string :phone
        t.string :url
        t.string :booking_methods, default: [], array: true
        t.string :booking_access
        t.integer :minimum_booking_period
        t.string :book_when
        t.time :latest_booking_time
        t.string :buy_when
        t.string :booking_url
        t.text :booking_notes

        t.references :line_referential
        t.references :line_provider, foreign_key: true, null: false

        t.timestamps
      end
    end
  end
end
