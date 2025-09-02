class AddCodeSpaceToPublicationApi < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      add_reference :publication_apis, :code_space
    end
  end
end
