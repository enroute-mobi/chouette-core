class Export::NetexFull < Export::Base
  include LocalExportSupport

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
    @document ||= Chouette::Netex::Document.new(self)
  end

  def generate_export_file
    build_netex_document
    document.temp_file
  end

  def operation_progress_weight(operation_name)
    operation_name.to_sym == :site_frame ? 90 : 10.0/4
  end

  def operations_progress_total_weight
    100
  end
end
