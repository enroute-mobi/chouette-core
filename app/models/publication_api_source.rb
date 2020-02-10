class PublicationApiSource < ActiveRecord::Base
  include RemoteFilesHandler

  belongs_to :publication_api
  belongs_to :publication
  belongs_to :export, class_name: 'Export::Base'

  validates :publication_api, presence: true
  validates :publication, presence: true

  before_save :cleanup_previous

  delegate :file, to: :export

  def self.generate_key(export)
    return unless export.present?

    out = []
    out << export.class.name.demodulize.downcase

    if export.is_a?(Export::Netex)
      out << export.export_type
      if export.export_type == "line"
        line = Chouette::Line.find export.line_code
        out << line.code
      end
    end

    out.join('-')
  end

  def public_url
    return unless key.present?

    base = publication_api.public_url
    setup = publication.publication_setup
    case setup.export_type.to_s
    when "Export::NetexFull"
      base += ".#{key}.xml"
    when "Export::Netex"
      if setup.export_options['export_type'] == 'full'
        base += ".#{key}.zip"
      else
        *split_key, line = key.split('-')
        base += "/lines/#{line}.#{split_key.join('-')}.zip"
      end
    else
      base += ".#{key}.zip"
    end
    
    base
  end

  def public_url_filename
    return unless public_url.present?

    url_object = URI.parse(public_url)
    url_path = url_object.path
    url_path.split("/").last
  end

  protected

  def cleanup_previous
    return unless export

    self.key ||= generate_key
    PublicationApiSource.where(publication_api_id: publication_api_id, key: key).destroy_all
  end

  def generate_key
    self.class.generate_key export
  end
end
