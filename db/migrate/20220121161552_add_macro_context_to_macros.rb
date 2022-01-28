class AddMacroContextToMacros < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_reference :macros, :macro_context, foreign_key: true
    end
  end
end
