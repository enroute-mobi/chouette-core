class AddStopAreaProviderReferenceToStopAreas < ActiveRecord::Migration[5.2]
  # / ! \ This migration has to be run only on CHOUETTE, not IBOO !
  def change
    on_public_schema_only do
      add_reference :stop_areas, :stop_area_provider, index: true
    end
  end

end
