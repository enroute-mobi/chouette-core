# frozen_string_literal: true

class RemoveFareCodeFromStopAreas < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      impacted_workgroup_ids = Chouette::StopArea.where.not(fare_code: nil).joins(stop_area_provider: :workbench).distinct.pluck(:workgroup_id)
      # Load every impacted Workgroup
      impacted_workgroups = Workgroup.where(id: impacted_workgroup_ids)

      impacted_workgroups.each do |workgroup|
        # .. to avoid Workgroup loading in loop :(
        CustomFieldsSupport.within_workgroup(workgroup) do
          code_space = workgroup.code_spaces.default
          stop_areas_with_fare_code = workgroup.stop_area_referential.stop_areas
                                        .where.not(fare_code: nil).includes(stop_area_provider: :workbench)

          # Migrate all Workgroup StopAreas
          stop_areas_with_fare_code.find_each do |stop_area|
            stop_area_provider = stop_area.stop_area_provider
            workbench = stop_area_provider.workbench
            fare_provider = workbench.default_fare_provider

            value = stop_area.fare_code

            zone = fare_provider.fare_zones.first_or_create_by_code(code_space, value) do |zone|
              zone.name = value
            end

            stop_area.stop_area_zones.create(zone: zone)
          end
        end
      end

      remove_column :stop_areas, :fare_code
    end
  end
end
