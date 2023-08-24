class DropTags < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      drop_table :tags
      drop_table :taggings
    end
  end
end
