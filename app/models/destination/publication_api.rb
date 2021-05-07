class Destination::PublicationApi < ::Destination
  validates_presence_of :publication_api_id
  validate :api_is_not_already_used

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

  def api_is_not_already_used
    return unless publication_api.present?

    scope = publication_api.publication_setups.where(export_type: publication_setup.export_type)
    scope = scope.where('publication_setups.id != ? AND publication_setups.publish_per_line = ?', publication_setup.id, publication_setup.publish_per_line) if publication_setup.persisted?

    return if scope.empty?

    errors.add(:publication_api_id, I18n.t('destinations.errors.publication_api.already_used'))
  end

  def generate_key(export)
    return nil unless export

    export_type = if export.is_a?(Export::NetexGeneric)
      "netex"
    else
      export.class.name.demodulize.downcase
    end

    if publication_setup.publish_per_line
      line = Chouette::Line.find export.line_ids.first
      "lines/#{line.registration_number}-#{export_type}.#{export.user_file.extension}"
    else
      "#{export_type}.#{export.user_file.extension}"
    end
  end
end
