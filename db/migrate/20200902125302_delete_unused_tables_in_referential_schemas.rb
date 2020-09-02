class DeleteUnusedTablesInReferentialSchemas < ActiveRecord::Migration[5.2]

  def unused_table_names
    # Tables unused for others schemas than public
    Apartment.excluded_models.map(&:constantize).map(&:table_name).map {|s| s.gsub(/public\./, '')}.uniq
  end

  def up
    not_in_public_schema do
      unused_table_names.each do |unused_table_name|
        drop_table unused_table_name
      end
    end
  end
end
