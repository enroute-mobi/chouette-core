class AddIgnoredSchemaRulesToFlamingoValidationSetups < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      add_column :flamingo_validation_setups, :ignored_schema_rules, :string
    end
  end
end
