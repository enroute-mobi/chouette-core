class UpdateLineProvider < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :line_providers, :name, :string

      LineProvider.reset_column_information
      LineProvider.find_each do |line_provider|
        line_provider.update(name: line_provider.short_name) unless line_provider.name
      end

      change_column_null :line_providers, :name, true
    end
  end
end
