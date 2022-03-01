class AddControlContextRunToControlRuns < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_reference :control_runs, :control_context_run, foreign_key: true
    end
  end
end
