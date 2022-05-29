class AddDescriptionToWorkgroup < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :workgroups do |t|
        t.string :description
      end
    end
  end
end
