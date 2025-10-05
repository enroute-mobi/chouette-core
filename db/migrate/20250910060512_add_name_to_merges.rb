class AddNameToMerges < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      change_table :merges do |t|
        t.string :name
      end

      Merge.find_each do |merge|
        next if merge.attributes['name'].present?

        merge.update name: "Finalisation du #{I18n.l(merge.created_at, format: :short_with_time, locale: :fr)}"
      end
    end
  end
end
