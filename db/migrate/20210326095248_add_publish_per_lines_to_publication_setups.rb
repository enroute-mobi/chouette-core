class AddPublishPerLinesToPublicationSetups < ActiveRecord::Migration[5.2]
  def change
    add_column :publication_setups, :publish_per_lines, :boolean, default: false
  end
end
