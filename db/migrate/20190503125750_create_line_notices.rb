class CreateLineNotices < ActiveRecord::Migration[5.2]
  def change
    create_table :line_notices do |t|
      t.integer :line_referential_id,  limit: 8
      t.string :title
      t.text :content
      t.string :objectid, :null => false
      t.text :import_xml
      t.jsonb :metadata, default: {}
      t.timestamps
    end
  end
end
