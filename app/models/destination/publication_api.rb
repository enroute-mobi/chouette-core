class Destination::PublicationApi < ::Destination
  validates_presence_of :publication_api_id

  def do_transmit(publication, report)
    publication.exports.successful.each do |export|
      key = generate_key(export)
      publication_api.publication_api_sources.find_or_create_by(key: key) do |publication_api_source|
        publication_api_source.export = export
        publication_api_source.publication = publication
        publication_api_source.key = key
      end if key
    end
  end

  def generate_key(export)
    return nil unless export

    export_type = if export.is_a?(Export::NetexGeneric)
      "netex"
    elsif export.is_a?(Export::Netex)
      "netex-full"
    else
      export.class.name.demodulize.downcase
    end

    if publication_setup.publish_per_line
      line = Chouette::Line.find export.line_ids.first
      "lines/#{line.registration_number}-#{export_type}.zip"
    else
      "#{export_type}.zip"
    end
  end
end
