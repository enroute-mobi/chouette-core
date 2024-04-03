# frozen_string_literal: true

class AddPostalRegionToEntrances < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :entrances, :postal_region, :string
    end
  end
end
