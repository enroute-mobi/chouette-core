class AddLocalesToStopAreaReferentials < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :stop_area_referentials, :locales, :jsonb, default: [{ code:'en_UK', default: true }, { code: 'fr_FR', default: true }]
    end
  end
end
