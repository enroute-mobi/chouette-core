# frozen_string_literal: true

# Provides Documents associated to a Published resource (line / stop area, etc)
class Api::V1::PublicationApi::DocumentsController < Api::V1::PublicationApi::BaseController
  include Downloadable

  rescue_from Date::Error do
    render status: :not_acceptable, plain: "Invalid valid_on parameter"
  end

  before_action :find_document!, only: %i[show]

  def show
    prepare_for_download @document
    filename_builder = FilenameBuilder.new(
      publication_api: publication_api,
      resource: published_resource,
      document: @document
    )
    send_file @document.file.path, filename: filename_builder.filename
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
        resource.model_name.element,
        resource_registration_number,
        document_type_short_name
      ].join('-')
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

  def published_resource # rubocop:disable Metrics/MethodLength
    return @published_resource if @published_resource

    resources = params[:resources]
    code = params[:registration_number]
    base_request = workgroup.send(resources).where(registration_number: code)

    if prefer_referent?
      @published_resource = begin
        base_request.where(is_referent: true).sole
      rescue ActiveRecord::RecordNotFound, ActiveRecord::SoleRecordExceeded
        nil
      end
      return @published_resource if @published_resource
    end

    @published_resource = base_request.sole
  end

  def find_document! # rubocop:disable Metrics/AbcSize
    @document = published_resource.documents.with_type(document_type).valid_on(validity_date).most_updated

    if @document.nil? && published_resource.referent?
      @document = workgroup.documents
                           .joins(:memberships).where(memberships: { documentable: published_resource.particulars })
                           .with_type(document_type).valid_on(validity_date).most_updated
    end

    render plain: 'Document Not Found', status: :not_found if @document.nil?
  end

  def prefer_referent?
    publication_api.prefer_referent_documents?
  end
end
