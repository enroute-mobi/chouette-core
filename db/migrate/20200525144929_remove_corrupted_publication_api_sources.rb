class RemoveCorruptedPublicationApiSources < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      # Remove publication api sources without any related publication
      PublicationApiSource.where.not(id: PublicationApiSource.joins(:publication)).destroy_all
      # Remove publication api sources without any related publication_api
      PublicationApiSource.where.not(id: PublicationApiSource.joins(:publication_api)).destroy_all
    end
  end
end
