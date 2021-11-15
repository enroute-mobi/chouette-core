class AddStatusToWorkbenches < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      add_column :workbenches, :status, :string
      add_column :workbenches, :invitation_code, :string, limit: 6
      add_column :workbenches, :accepted_at, :datetime

      Workbench.update_all(status: :accepted)
    end
  end

  def down
    on_public_schema_only do
      remove_column :workbenches, :status
      remove_column :workbenches, :invitation_code
    end
  end
end
