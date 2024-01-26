class RemovePublishPerLine < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_column :publication_setups, :publish_per_line
    end
  end
end
