# frozen_string_literal: true

class AddIndexToConnectionLinks < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_index :connection_links, :departure_id
      add_index :connection_links, :arrival_id
    end
  end
end
