class AddChecksumIndexes < ActiveRecord::Migration[5.2]
  def change
    change_table :routes do |t|
      t.index :checksum
    end
    change_table :journey_patterns do |t|
      t.index :checksum
    end
    change_table :vehicle_journeys do |t|
      t.index :checksum
    end
  end
end
