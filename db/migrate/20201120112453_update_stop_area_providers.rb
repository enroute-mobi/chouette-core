class UpdateStopAreaProviders < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      # Remove useless column
      remove_reference :organisations, :stop_area_provider

      # Link StopAreaProvider to a Workbench
      add_reference :stop_area_providers, :workbench, index: true
      StopAreaProvider.reset_column_information

      # Create default StopAreaProviders ... when needed
      Workbench.find_each do |workbench|
        workbench.default_stop_area_provider
        workbench.save
      end

      # Link directly StopArea with its StopAreaProvider
      add_reference :stop_areas, :stop_area_provider, index: true
      Chouette::StopArea.reset_column_information

      # Before removing stop_area_providers_areas table, the StopAreas are associated to the 'first' StopAreaProvider
      Chouette::StopArea.joins('INNER JOIN stop_area_providers_areas on stop_area_providers_areas.stop_area_id = stop_areas.id').
        select('id', 'stop_area_providers_areas.stop_area_provider_id as stop_area_provider_id').find_each do |stop_area|
        stop_area.update_column :stop_area_provider_id, stop_area.stop_area_provider_id
      end

      drop_table :stop_area_providers_areas do |t|
        t.bigint "stop_area_provider_id"
        t.bigint "stop_area_id"
        t.index ["stop_area_provider_id", "stop_area_id"], name: "stop_areas_stop_area_providers_compound"
      end

      # Should ignore production Workgroups with several Workbenches
      Workgroup.includes(workbenches: :stop_area_providers).find_each do |workgroup|
        if workgroup.workbenches.many?
          Rails.logger.info "Ignore Workgroup #{workgroup.name}"
          next
        end

        default_workbench = workgroup.workbenches.first

        existing_stop_area_providers = workgroup.stop_area_referential.stop_area_providers.where(workbench_id: nil)
        existing_stop_area_providers.update_all workbench_id: default_workbench.id

        stop_area_provider = default_workbench.default_stop_area_provider
        stop_areas = workgroup.stop_area_referential.stop_areas.where(stop_area_provider_id: nil)

        stop_areas.update_all stop_area_provider_id: stop_area_provider.id
      end
    end
  end
end
