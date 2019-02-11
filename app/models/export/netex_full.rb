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

  def journeys
    @journeys ||= Chouette::VehicleJourney.all
  end

  def document
    @document ||= Chouette::Netex::Document.new(referential)
  end

  def generate_export_file
    build_netex_document
    document.temp_file
  end
end
