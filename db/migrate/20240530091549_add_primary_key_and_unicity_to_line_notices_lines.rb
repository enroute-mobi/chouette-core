# frozen_string_literal: true

class AddPrimaryKeyAndUnicityToLineNoticesLines < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      add_column :line_notices_lines, :id, :primary_key
      remove_index :line_notices_lines, name: 'index_line_notices_lines_on_line_notice_id_and_line_id'
      add_index :line_notices_lines, %i[line_notice_id line_id], unique: true
      add_index :line_notices_lines, :line_id
    end
  end

  def down
    on_public_schema_only do
      remove_column :line_notices_lines, :id
      ad_index :line_notices_lines,
               %i[line_notice_id line_id],
               name: 'index_line_notices_lines_on_line_notice_id_and_line_id'
      remove_index :line_notices_lines, name: 'index_line_notices_lines_on_line_notice_id_and_line_id'
      remove_index :line_notices_lines, name: 'index_line_notices_lines_on_line_id'
    end
  end
end
