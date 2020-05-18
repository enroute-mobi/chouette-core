module PublicationsHelper
  def destination_metadatas destination
    metadatas = {}
    metadatas.update( Destination.tmf(:type) => destination.human_type )
    metadatas.update( Destination.tmf(:name) => destination.name )
    metadatas.update( PublicationApi.ts => link_to(destination.publication_api.name, [destination.publication_api.workgroup, destination.publication_api]) ) if destination.publication_api.present?
    destination.options.each do |k, v|
      metadatas.update( translate_option_key(destination.class, k) => translate_option_value(destination.class, k, v) )
    end
    metadatas
  end

end
