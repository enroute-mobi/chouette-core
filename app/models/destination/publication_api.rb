# frozen_string_literal: true

class Destination
  class PublicationApi < ::Destination
    belongs_to :publication_api, optional: false, class_name: '::PublicationApi'

    validate :api_is_not_already_used

    def do_transmit(publication, report)
      unless publication_api
        report.failed! message: I18n.t('destinations.errors.publication_api.empty')
        return
      end

      return unless (export = publication.export)

      key = generate_key(export)
      return unless key

      publication_api_source = publication_api.publication_api_sources.find_or_create_by(key: key)
      publication_api_source.export = export
      publication_api_source.publication = publication
      publication_api_source.key = key

      publication_api_source.save
    end

    def api_is_not_already_used
      return unless publication_api

      scope = publication_api.publication_setups.same_api_usage(publication_setup)
      if scope.exists?
        errors.add(:publication_api_id, I18n.t('destinations.errors.publication_api.already_used'))
        false
      else
        true
      end
    end

    def generate_key(export)
      return nil unless export

      export_type =
        if export.is_a?(Export::NetexGeneric)
          'netex'
        else
          export.class.name.demodulize.downcase
        end

      "#{export_type}.#{export.user_file.extension}"
    end
  end
end
