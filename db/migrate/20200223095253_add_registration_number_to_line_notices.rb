class AddRegistrationNumberToLineNotices < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :line_notices, :registration_number, :string
    end
  end
end
