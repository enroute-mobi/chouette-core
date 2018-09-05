class AddOptionsToImports < ActiveRecord::Migration
  def change
    add_column :imports, :options, :hstore
  end
end
