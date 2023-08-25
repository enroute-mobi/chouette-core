class RemoveSentinelFromWorkgroup < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      NotificationRule.where(notification_type: 'hole_sentinel').delete_all

      remove_column :workgroups, :sentinel_delay
      remove_column :workgroups, :sentinel_min_hole_size
    end
  end
end
