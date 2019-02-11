class Export::NetexFull < Export::Base
  include LocalExportSupport

  option :duration, required: true, type: :integer, default_value: 200

  def self.file_extension_whitelist
    %w(xml)
  end

  def worker_class
    NetexFullExportWorker
  end

  def build_netex_document
    document.build
  end

  def document
    @document ||= Chouette::Netex::Document.new(referential, date_range)
  end

  def generate_export_file
    build_netex_document
    document.temp_file
  end
end
