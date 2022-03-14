class RemoveContraintMessageKeyInControlMessages < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_column :control_messages, :message_key, :string, null: true
    end
  end
end
