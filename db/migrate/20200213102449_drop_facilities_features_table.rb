class DropFacilitiesFeaturesTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :facilities_features do |t|
      t.integer :facility_id, :limit => 8
      t.integer :choice_code
    end
  end
end
