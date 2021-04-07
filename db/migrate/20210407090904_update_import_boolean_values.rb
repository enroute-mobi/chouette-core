class UpdateImportBooleanValues < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      %w(automatic_merge archive_on_fail flag_urgent).each do |name|
        Import::Workbench.where.not("CAST(options ->> ? AS BOOLEAN)", name).update_all("options = jsonb_set(options, '{#{name}}', 'false')")
        Import::Workbench.where("CAST(options ->> ? AS BOOLEAN)", name).update_all("options = jsonb_set(options, '{#{name}}', 'true')")
      end
    end
  end
end
