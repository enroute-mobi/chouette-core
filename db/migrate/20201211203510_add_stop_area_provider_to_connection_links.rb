class AddStopAreaProviderToConnectionLinks < ActiveRecord::Migration[5.2]
  def change
  	on_public_schema_only do
      change_table :connection_links do |t|
        t.belongs_to :stop_area_provider
      end
      Chouette::ConnectionLink.reset_column_information

      # Should ignore production Workgroups with several Workbenches
      Workgroup.includes(workbenches: :stop_area_providers).find_each do |workgroup|
        if workgroup.workbenches.many?
          Rails.logger.info "Ignore Workgroup #{workgroup.name}"
          next
        end

        default_workbench = workgroup.workbenches.first
        stop_area_provider = default_workbench.default_stop_area_provider

        connection_links = workgroup.stop_area_referential.connection_links.where(stop_area_provider_id: nil)
        connection_links.update_all stop_area_provider_id: stop_area_provider.id
      end
    end
  end
end
