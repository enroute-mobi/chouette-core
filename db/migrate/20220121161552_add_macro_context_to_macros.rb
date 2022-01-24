class AddMacroContextToMacros < ActiveRecord::Migration[5.2]
  def change
    add_reference :macros, :macro_context, foreign_key: true
  end
end
