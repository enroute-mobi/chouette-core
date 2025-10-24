class AddForAssociationToTaggings < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      add_column :taggings, :for_association, :string, default: nil

      change_table :taggings do |t|
        t.remove_index name: 'index_taggings_on_taggable_type_and_taggable_id_and_tag_id'
        t.index ["taggable_type", "taggable_id", "tag_id", "for_association"], name: 'index_taggings_on_taggable_and_tag_id_and_for_association', unique: true
        t.index ["taggable_type", "taggable_id", "tag_id"], where: 'for_association IS NULL', unique: true
      end
    end
  end
end
