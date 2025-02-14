class AddFlexibleLineTypeAndBookingArrangementToLines < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      add_column :lines, :flexible_line_type, :string
      add_reference :lines, :booking_arrangement, foreign_key: true, null: true

      Chouette::Line.reset_column_information
      Chouette::Line.where(flexible_service: true).update_all(flexible_line_type: 'other')

      remove_column :lines, :flexible_service
    end
  end

  def down
    on_public_schema_only do
      add_column :lines, :flexible_service, :boolean, default: false

      Chouette::Line.reset_column_information
      Chouette::Line.where(flexible_line_type: 'other').update_all(flexible_service: true)

      remove_column :lines, :flexible_line_type
      remove_column :lines, :booking_arrangement_id
    end
  end
end