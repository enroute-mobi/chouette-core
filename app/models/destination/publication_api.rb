class Destination::PublicationApi < ::Destination
  validates_presence_of :publication_api_id

  def do_transmit(publication, report)
    publication.exports.successful.each do |export|
      PublicationApiSource.create publication_api: publication_api, publication: publication, export: export
    end
  end
end
