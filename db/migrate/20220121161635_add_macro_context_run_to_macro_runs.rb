class AddMacroContextRunToMacroRuns < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_reference :macro_runs, :macro_context_run, foreign_key: true
    end
  end
end
