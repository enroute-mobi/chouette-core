class AddBookingArrangementToJourneyPattern < ActiveRecord::Migration[6.1]
  def change
    add_reference :journey_patterns, :booking_arrangement, null: true, index: false
  end
end
