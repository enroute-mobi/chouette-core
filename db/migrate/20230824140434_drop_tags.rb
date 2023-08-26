class DropTags < ActiveRecord::Migration[5.2]
  def change
    drop_table :tags
    drop_table :taggings
  end
end
