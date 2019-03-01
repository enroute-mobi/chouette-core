class AddOrganisationIdTDelayedJobs < ActiveRecord::Migration
  def change
    add_column :delayed_jobs, :organisation_id, :integer, limit: 8
    add_index :delayed_jobs, :organisation_id
  end
end
