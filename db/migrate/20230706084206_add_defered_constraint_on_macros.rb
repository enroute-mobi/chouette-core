# frozen_string_literal: true

class AddDeferedConstraintOnMacros < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      remove_index :macros, name: :index_macros_on_macro_list_id_and_position
      add_index :macros, %i[macro_list_id macro_context_id position], unique: true, name: 'index_macros_position'

      execute <<-SQL
        ALTER TABLE macros ADD CONSTRAINT index_macros_position UNIQUE USING INDEX index_macros_position DEFERRABLE INITIALLY DEFERRED;
      SQL
    end
  end

  def down
    on_public_schema_only do
      execute <<-SQL
        ALTER TABLE macros DROP CONSTRAINT index_macros_position;
      SQL
      add_index :macros, %i[macro_list_id position], unique: true
    end
  end
end
