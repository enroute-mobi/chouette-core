class AddUserLocaleAndTimeZoneAttributesToUsers < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :users, :user_locale, :string, :default => "fr_FR"
      add_column :users, :time_zone, :string, :limit => 255, :default => "Paris"
    end
  end
end
