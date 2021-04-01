class PublicationApiSource < ActiveRecord::Base
  include RemoteFilesHandler

  belongs_to :publication_api
  belongs_to :publication
  belongs_to :export, class_name: 'Export::Base'

  validates :publication_api, presence: true
  validates :publication, presence: true

  before_save :cleanup_previous

  delegate :file, to: :export

  def public_url
    return unless key.present?

    @public_url ||= if publication_setup.publish_per_line
      line = key_source.shift
      "#{publication_api_url}/lines/#{line}.#{key_source.join('-')}.zip"
    else
      "#{publication_api_url}.#{generate_key}.zip"
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

  def cleanup_previous
    return unless export

    self.key ||= generate_key
    PublicationApiSource.where(publication_api_id: publication_api_id, key: key).destroy_all
  end

  def generate_key
    return unless export.present?

    key_source.join('-')
  end

  def key_source
    @key_source ||= [].tap do |key_source|
      if publication_setup.publish_per_line
        line = Chouette::Line.find  export.line_ids.first
        key_source << line.registration_number
      end

      key_source << export.class.name.demodulize.downcase

      if export.is_a?(Export::Netex)
        key_source << "full"
      end
    end
  end
end
