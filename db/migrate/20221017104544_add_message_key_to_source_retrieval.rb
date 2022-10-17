class AddMessageKeyToSourceRetrieval < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :source_retrievals, :message_key, :string, null: true
    end
  end
end
