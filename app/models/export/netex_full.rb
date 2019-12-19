class Export::NetexFull < Export::Base
  include LocalExportSupport

  def self.file_extension_whitelist
    %w(xml)
  end

  def build_netex_document
    document.build
  end

  def document
    @document ||= Chouette::Netex::Document.new(self)
  end

  def generate_export_file
    build_netex_document
    document.temp_file
  end

  def content_type
    'text/xml'
  end

  protected

  # File extension used to send exported file to the user.
  # Can be overrided by sub classes
  def user_file_extension
    "xml"
  end

end
