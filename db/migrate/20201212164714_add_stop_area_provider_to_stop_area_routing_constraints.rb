class AddStopAreaProviderToStopAreaRoutingConstraints < ActiveRecord::Migration[5.2]
  def change
  	on_public_schema_only do
      change_table :stop_area_routing_constraints do |t|
        t.belongs_to :stop_area_referential
        t.belongs_to :stop_area_provider
      end
      StopAreaRoutingConstraint.reset_column_information

      StopAreaRoutingConstraint.includes(:from).find_each do |routing_constraint|
        routing_constraint.update stop_area_referential_id: routing_constraint.from.stop_area_referential_id
      end

      # Should ignore production Workgroups with several Workbenches
      Workgroup.includes(workbenches: :stop_area_providers).find_each do |workgroup|
        if workgroup.workbenches.many?
          Rails.logger.info "Ignore Workgroup #{workgroup.name}"
          next
        end

        default_workbench = workgroup.workbenches.first
        stop_area_provider = default_workbench.default_stop_area_provider

        routing_constraints = workgroup.stop_area_referential.stop_area_routing_constraints.where(stop_area_provider_id: nil)
        routing_constraints.update_all stop_area_provider_id: stop_area_provider.id
      end
    end
  end
end
