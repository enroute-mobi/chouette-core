class AddTransportModesToWorkgroups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :workgroups, :transport_modes, :jsonb, default: TransportModeEnumerations.full_transport_modes
    end
  end
end
