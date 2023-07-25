class AddIsReferentAndReferentToLines < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :lines, :is_referent, :boolean, default: false
      add_reference :lines, :referent, index: true
    end
  end
end
