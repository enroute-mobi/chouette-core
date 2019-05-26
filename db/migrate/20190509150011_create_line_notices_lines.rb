class CreateLineNoticesLines < ActiveRecord::Migration[5.2]
  def change
    create_join_table :line_notices, :lines do |t|
      t.index [:line_notice_id, :line_id]
    end
  end
end
