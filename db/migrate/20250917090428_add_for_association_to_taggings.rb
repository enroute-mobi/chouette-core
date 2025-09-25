class AddForAssociationToTaggings < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      add_column :taggings, :for_association, :string, default: nil
    end
  end
end
