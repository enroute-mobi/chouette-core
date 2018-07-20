class AssociateApiKeysToWorkbench < ActiveRecord::Migration
  def change
    remove_column :api_keys, :referential_id
    add_column :api_keys, :workbench_id, :integer

    Api::V1::ApiKey.all.each do |key|
      key.update_column(:workbench_id, key.organisation.workbenches.first&.id)
    end

    remove_column :api_keys, :organisation_id
  end
end
