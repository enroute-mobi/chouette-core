class AddIsReferentAndReferentToCompanies < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :companies, :is_referent, :boolean, default: false
      add_reference :companies, :referent, index: true
    end
  end
end
