class AddRequiredTagsAndExcludedTagsToProcessingRules < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      add_column :processing_rules, :required_tag_ids, :integer, array: true, default: []
      add_column :processing_rules, :excluded_tag_ids, :integer, array: true, default: []
    end
  end
end
