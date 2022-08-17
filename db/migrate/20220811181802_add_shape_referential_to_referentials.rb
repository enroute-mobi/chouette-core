class AddShapeReferentialToReferentials < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_reference :referentials, :shape_referential, foreign_key: true
    end
  end
end
