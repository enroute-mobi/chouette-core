# frozen_string_literal: true

class RemoveOrphanMacroContexts < ActiveRecord::Migration[7.2]
  def up
    on_public_schema_only do
      Macro::Context.left_outer_joins(:macro_list).where(Macro::List.quoted_table_name => { id: nil }).destroy_all
    end
  end

  def down; end
end
