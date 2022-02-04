class Import::NetexGeneric < Import::Base
  include LocalImportSupport
  include Imports::WithoutReferentialSupport

  def self.accepts_file?(file)
    case File.extname(file)
    when ".xml"
      true
    when ".zip"
      Zip::File.open(file) do |zip_file|
        files_count = zip_file.glob('*').size
        zip_file.glob('*.xml').size == files_count
      end
    else
      false
    end
  rescue => e
    Chouette::Safe.capture "Error in testing NeTEx (Generic) file: #{file}", e
    false
  end

  def file_extension_whitelist
    %w(zip xml)
  end

  # stop_areas
  def stop_area_provider
    @stop_area_provider ||= workbench.default_stop_area_provider
  end
  attr_writer :stop_area_provider

  def import_stop_areas
    Chouette::Sync::Referential.new(stop_area_provider).tap do |sync|
      sync.synchronize_with Chouette::Sync::StopArea::Netex
      #sync.synchronize_with Chouette::Sync::Entrance::Netex

      sync.import = self
      sync.source = netex_source

      sync.update_or_create
    end
  end

  # lines
  def line_provider
    @line_provider ||= workbench.default_line_provider
  end
  attr_writer :line_provider

  def import_lines
    Chouette::Sync::Referential.new(line_provider).tap do |sync|
      sync.synchronize_with Chouette::Sync::Company::Netex
      sync.synchronize_with Chouette::Sync::Network::Netex
      sync.synchronize_with Chouette::Sync::LineNotice::Netex
      sync.synchronize_with Chouette::Sync::Line::Netex

      sync.import = self
      sync.source = netex_source

      sync.update_or_create
    end
  end

  def import_without_status
    import_resources :stop_areas
  end

  def netex_source
    @netex_source ||= Netex::Source.read(local_file.path, type: file_extension)
  end

  def line_ids
    []
  end
end
