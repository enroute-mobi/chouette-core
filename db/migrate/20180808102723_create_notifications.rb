class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.json :payload
      t.string :channel

      t.timestamps null: false
    end
  end
end
