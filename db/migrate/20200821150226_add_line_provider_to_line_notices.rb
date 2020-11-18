class AddLineProviderToLineNotices < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table :line_notices do |t|
        t.belongs_to :line_provider
      end

      Workbench.find_each do |workbench|
        workbench.lines.each do |line|
          line.line_notices.update_all line_provider_id: workbench.default_line_provider.id
        end
      end
    end
  end

  def down
    remove_column :line_notices, :line_provider_id if column_exists? :line_notices, :line_provider_id
  end
end
