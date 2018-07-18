class AddContextToComplianceCheckSets < ActiveRecord::Migration
  def change
    add_column :compliance_check_sets, :context, :string
  end
end
