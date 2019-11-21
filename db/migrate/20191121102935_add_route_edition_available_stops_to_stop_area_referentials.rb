class AddRouteEditionAvailableStopsToStopAreaReferentials < ActiveRecord::Migration[5.2]
  def change
  	on_public_schema_only do
    	add_column :stop_area_referentials, :route_edition_available_stops, :jsonb, default: {zdep: true, zdlp: false, lda: false, gdl: false}
    end
  end
end
