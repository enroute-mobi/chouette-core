# frozen_string_literal: true

class CreateSequences < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :sequences do |t|
        t.string :name
        t.string :sequence_type
        t.integer :range_start
        t.integer :range_end
        t.text :description
        t.references :workbench
        t.timestamps
      end
    end
  end
end
