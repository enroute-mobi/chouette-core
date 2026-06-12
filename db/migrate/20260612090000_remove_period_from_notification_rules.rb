# frozen_string_literal: true

class RemovePeriodFromNotificationRules < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      NotificationRule.where.not(period: nil).delete_all

      Search::Save.where(search_type: 'Search::NotificationRule')
                  .update_all("search_attributes = search_attributes - 'start_date' - 'end_date'")

      remove_column :notification_rules, :period
    end
  end
end
