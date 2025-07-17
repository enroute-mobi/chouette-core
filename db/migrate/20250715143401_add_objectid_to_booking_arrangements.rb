# frozen_string_literal: true

class AddObjectidToBookingArrangements < ActiveRecord::Migration[7.0]
  def up # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      change_table :booking_arrangements do |t|
        t.string :objectid
        t.index :objectid, unique: true
      end

      ::BookingArrangement.find_each do |ba|
        ba.before_validation_objectid
        ba.save(validate: false, touch: false)
      end

      change_column :booking_arrangements, :objectid, :string, null: false
    end
  end

  def down
    on_public_schema_only do
      change_table :booking_arrangements do |t|
        t.remove :objectid
      end
    end
  end
end
