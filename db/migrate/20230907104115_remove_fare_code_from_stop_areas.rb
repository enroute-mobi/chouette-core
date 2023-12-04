class RemoveFareCodeFromStopAreas < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      Chouette::StopArea.where.not(fare_code: nil).includes(stop_area_provider: {workbench: :workgroup}).find_each do |stop_area|
        stop_area_provider = stop_area.stop_area_provider
        workbench = stop_area_provider.workbench
        workgroup = workbench.workgroup

        fare_provider = workbench.default_fare_provider
        code_space = workgroup.code_spaces.default
        value = stop_area.fare_code

        zone = fare_provider.fare_zones.first_or_create_by_code(code_space, value) do |zone|
          zone.name = value
        end

        stop_area.stop_area_zones.create(zone: zone)
      end

      remove_column :stop_areas, :fare_code
    end
  end
end
