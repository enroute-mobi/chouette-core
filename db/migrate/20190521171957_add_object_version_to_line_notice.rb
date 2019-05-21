class AddObjectVersionToLineNotice < ActiveRecord::Migration[5.2]
  def change
    add_column :line_notices, :object_version, :integer
  end
end
