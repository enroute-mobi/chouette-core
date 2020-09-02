class CreateLineProviders < ActiveRecord::Migration[5.2]
  def up
  	on_public_schema_only do
  		create_table :line_providers do |t|
        t.string :short_name, null: false
        t.belongs_to :workbench, null: false
        t.belongs_to :line_referential, null: false

        t.timestamps
      end

      change_table :lines do |t|
        t.belongs_to :line_provider
      end

      change_table :companies do |t|
        t.belongs_to :line_provider
      end

      change_table :networks do |t|
        t.belongs_to :line_provider
      end

      change_table :group_of_lines do |t|
        t.belongs_to :line_provider
      end

      Workbench.find_each do |workbench|
        workbench.create_default_line_provider
        workbench.lines.update_all line_provider_id: workbench.default_line_provider.id
        workbench.companies.update_all line_provider_id: workbench.default_line_provider.id
        workbench.networks.update_all line_provider_id: workbench.default_line_provider.id
        workbench.group_of_lines.update_all line_provider_id: workbench.default_line_provider.id
      end
  	end
  end

  def down
  	remove_column :lines, :line_provider_id if column_exists? :lines, :line_provider_id
  	remove_column :companies, :line_provider_id if column_exists? :companies, :line_provider_id
  	remove_column :networks, :line_provider_id if column_exists? :networks, :line_provider_id
  	remove_column :group_of_lines, :line_provider_id if column_exists? :group_of_lines, :line_provider_id

  	drop_table :line_providers if table_exists? :line_providers
  end
end
