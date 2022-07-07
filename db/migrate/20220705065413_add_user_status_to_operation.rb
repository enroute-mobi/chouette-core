class AddUserStatusToOperation < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      Operation.descendants.each do |operation_class|
        add_column operation_class.table_name, :user_status, :string

        operation_class.reset_column_information

        # Define default UserStatus according to Operation status
        operation_class.without_status(:done).update_all(user_status: :pending)
        operation_class.with_status(:done).where(error_uuid: nil).update_all(user_status: :successful)
        operation_class.with_status(:done).where.not(error_uuid: nil).update_all(user_status: :failed)

        change_column_null operation_class.table_name, :user_status, false
      end
    end
  end

  def down
    on_public_schema_only do
      Operation.descendants.each do |operation_class|
        remove_column operation_class.table_name, :user_status
      end
    end
  end
end
