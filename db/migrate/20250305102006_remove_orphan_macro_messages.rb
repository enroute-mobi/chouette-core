# frozen_string_literal: true

class RemoveOrphanMacroMessages < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      Macro::Message.left_outer_joins(:macro_run).where(macro_runs: { id: nil }).delete_all
    end
  end

  def down; end
end
