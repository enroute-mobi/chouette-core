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

  def publication_processing_helper(object)
    simple_block_for object, title: I18n.t("simple_block_for.title.processing"), class: "col-lg-6 col-md-6 col-sm-12 col-xs-12" do |b|
      content = b.attribute :created_at, as: :datetime
      content += b.attribute :started_at, as: :datetime
      content += b.attribute :ended_at, as: :datetime
      content + b.attribute(:duration, value: object.ended_at.presence && object.started_at.presence && object.ended_at - object.started_at)
    end
  end

end
