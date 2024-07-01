# frozen_string_literal: true

class AddHiddenToWorkbenches < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :workbenches do |t|
        t.boolean :hidden, null: false, default: false
      end
    end
  end
end
