class AddWorkbenchToStopAreaProvider < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_reference :organisations, :stop_area_provider
      add_reference :stop_area_providers, :workbench, index: true
    end
  end
end
