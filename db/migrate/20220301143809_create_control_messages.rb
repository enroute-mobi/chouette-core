class CreateControlMessages < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :control_messages do |t|
        t.references :source, polymorphic: true
        t.references :control_run

        t.string :message_key
        t.string :criticity
        t.jsonb :message_attributes, default: {}
        t.timestamps
      end
    end
  end
end
