class AddIgnoreChecksumAndEnabledToSources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :sources, :enabled, :boolean, default: true
      add_column :sources, :ignore_checksum, :boolean, default: false
    end
  end
end
