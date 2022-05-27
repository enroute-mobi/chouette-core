class AddStatusToWorkbenches < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :workbenches do |t|
        t.string :invitation_code, limit: 6
      end
    end
  end
end
