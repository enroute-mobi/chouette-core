class AddShapeToJourneyPatterns < ActiveRecord::Migration[5.2]
  def change
    add_reference :journey_patterns, :shape
  end
end
