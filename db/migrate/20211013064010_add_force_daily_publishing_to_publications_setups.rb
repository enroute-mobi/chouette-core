class AddForceDailyPublishingToPublicationsSetups < ActiveRecord::Migration[5.2]
  def change
    add_column :publication_setups, :force_daily_publishing, :boolean, default: false
  end
end
