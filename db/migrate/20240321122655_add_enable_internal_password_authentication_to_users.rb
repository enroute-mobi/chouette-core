# frozen_string_literal: true

class AddEnableInternalPasswordAuthenticationToUsers < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :users do |t|
        t.boolean :enable_internal_password_authentication, null: false, default: false
      end
    end
  end
end
