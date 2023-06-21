class AddReferentialCreatedAtToAggregateResources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :aggregate_resources, :referential_created_at, :datetime

      Aggregate::Resource.reset_column_information

      Aggregate::Resource.find_each do |resource|
        referential_created_at = Time.zone.parse(resource.referential_name)
        resource.update_attribute :referential_created_at, referential_created_at
      end

      change_column_null :aggregate_resources, :referential_created_at, false
      remove_column :aggregate_resources, :referential_name
    end
  end
end
