class UpdateLocalizationKeys < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      new_keys = HashWithIndifferentAccess.new(
        fr: "fr_FR",
        gb: "en_UK",
        nl: "nl_NL",
        es: "es_ES",
        it: "it_IT",
        de: "de_DE"
      )
      Chouette::StopArea.where.not(localized_names: nil).find_each do |s|
        new_names = s[:localized_names].map{ |k, v| [new_keys[k], v]}.to_h
        s.update_column :localized_names, new_names
      end
    end
  end
end
