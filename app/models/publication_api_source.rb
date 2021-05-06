class PublicationApiSource < ActiveRecord::Base
  include RemoteFilesHandler

  belongs_to :publication_api
  belongs_to :publication
  belongs_to :export, class_name: 'Export::Base'

  validates :publication_api, presence: true
  validates :publication, presence: true

  delegate :file, to: :export

  def public_url
    return unless key.present?

    @public_url ||= if publication_setup.publish_per_line
      "#{publication_api_url}/#{key}"
    else
      "#{publication_api_url}.#{key}"
    end
  end

  def public_url_filename
    return unless public_url.present?

    url_object = URI.parse(public_url)
    url_path = url_object.path
    url_path.split("/").last
  end

  protected

  def publication_setup
    @publication_setup ||= publication.publication_setup
  end

  def publication_api_url
    @publication_api_url ||= publication_api.public_url
  end

end
