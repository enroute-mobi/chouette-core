# frozen_string_literal: true

class RemoveNullConstraintOnFootnotesLineId < ActiveRecord::Migration[7.2]
  def up
    change_column :footnotes, :line_id, :bigint, null: true
  end

  def down
    change_column :footnotes, :line_id, :bigint, null: false
  end
end
