class AddPublishPerLinesToPublicationSetups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :publication_setups, :publish_per_line, :boolean, default: false
    end
  end
end
