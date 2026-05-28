# frozen_string_literal: true

class SetStopAreaProvidersAllowedStopAreaTypesDefaultValue < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      connection.execute(
        %(UPDATE "public"."stop_area_providers" SET "allowed_stop_area_types" = '{}' WHERE "public"."stop_area_providers"."allowed_stop_area_types" IS NULL)
      )
      change_column :stop_area_providers, :allowed_stop_area_types, :string, array: true, null: false, default: []
    end
  end
end
