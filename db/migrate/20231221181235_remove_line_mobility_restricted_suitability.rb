class RemoveLineMobilityRestrictedSuitability < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      Chouette::Line.where(mobility_restricted_suitability: true).
        update_all(mobility_impaired_accessibility: 'yes')

      remove_column :lines, :mobility_restricted_suitability
    end
  end
end
