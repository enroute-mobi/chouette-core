# frozen_string_literal: true

class CreateTagsAndTaggings < ActiveRecord::Migration[7.0]
  def change # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      create_table :tags do |t|
        t.string :name, null: false
        t.string :color
        t.text :description

        t.references :workbench

        t.timestamps
      end

      create_table :taggings do |t|
        t.references :tag, null: false
        t.references :taggable, polymorphic: true, null: false, index: false

        t.timestamps
      end

      add_index :tags, %i[workbench_id name], unique: true
      add_index :taggings, %i[taggable_type taggable_id tag_id], unique: true
    end
  end
end