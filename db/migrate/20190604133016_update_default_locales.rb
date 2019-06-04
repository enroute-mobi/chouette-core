class UpdateDefaultLocales < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      default = ["fr_FR","en_UK","nl_NL","es_ES","it_IT","de_DE"].map do |l| { code:l, default: true } end
      change_column :stop_area_referentials, :locales, :jsonb, default: default
      StopAreaReferential.update_all locales: default
    end
  end
end
