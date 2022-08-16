# frozen_string_literal: true

# Provides Documents associated to a Published resource (line / stop area, etc)
class Api::V1::PublicationApi::DocumentsController < Api::V1::PublicationApi::Base
  include Downloadable

  rescue_from Date::Error do
    render status: :not_acceptable, plain: "Invalid valid_on parameter"
  end

  def show
    document = published_resource.documents.with_type(document_type).valid_on(validity_date).most_updated!
    prepare_for_download document

    filename = FilenameBuilder.new(publication_api: publication_api, resource: published_resource, document: document).filename

    send_file document.file.path, filename: filename
  end

  # Create filename with the Document
  class FilenameBuilder
    def initialize(publication_api:, resource:, document:)
      @publication_api = publication_api
      @resource = resource
      @document = document
    end
    attr_reader :publication_api, :resource, :document

    def filename
      "#{basename}.#{extension}"
    end

    delegate :document_type, to: :document
    delegate :slug, to: :publication_api, prefix: true
    delegate :registration_number, to: :resource, prefix: true
    delegate :short_name, to: :document_type, prefix: true

    def basename
      [
        publication_api_slug,
        resource_type,
        resource_registration_number,
        document_type_short_name
      ].join('-')
    end

    def resource_type
      # TODO: manage other kind of resource like StopArea
      'line'
    end

    def extension
      document.file.file.extension
    end
  end

  protected

  def validity_date
    if (date = params[:valid_on])
      Date.parse(date)
    else
      Date.current
    end
  end

  def document_type
    workgroup.document_types.find_by! short_name: params[:document_type]
  end

  def published_resource
    # TODO: manage other kind of resource like StopArea
    published_referential.lines.where(registration_number: params[:line_registration_number]).sole
  end
end
