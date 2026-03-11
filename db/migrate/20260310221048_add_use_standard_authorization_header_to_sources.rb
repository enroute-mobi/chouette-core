class AddUseStandardAuthorizationHeaderToSources < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      add_column :sources, :use_standard_authorization_header, :boolean, default: true, null: false
    end
  end
end
