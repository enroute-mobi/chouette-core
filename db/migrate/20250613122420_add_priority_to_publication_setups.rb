# frozen_string_literal: true

class AddPriorityToPublicationSetups < ActiveRecord::Migration[6.1]
  def change
    on_public_schema_only do
      change_table :publication_setups do |t|
        t.integer :priority, null: false, default: 1
      end
    end
  end
end
