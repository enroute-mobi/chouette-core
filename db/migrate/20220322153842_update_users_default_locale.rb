class UpdateUsersDefaultLocale < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_column :users, :user_locale, :string, default: 'fr'

      User.where(user_locale: 'fr_FR').update_all(user_locale: 'fr')
    end
  end
end
