# Imports Shapes defined into a 'zip' Shapefile in the Workbench ShapeReferential
class Import::Shapefile < Import::Base
  include LocalImportSupport
  include Measurable

  # Used by Import::Workbench to test the imported file
  def self.accepts_file?(file)
    Archive.valid? file
  end

  # Overrides #import method to remove referential management
  def import
    measure "import_#{import_type}", id: id do
      update status: 'running', started_at: Time.now

      import_without_status
      @status ||= 'successful'

      update status: @status, ended_at: Time.now
    end
  rescue => e
    update status: 'failed', ended_at: Time.now
    Chouette::Safe.capture "#{self.class.name} ##{id} failed", e
  ensure
    save

    # Invoke the freaky logic /o\
    notify_parent

    notify_state
  end

  # TODO Makes a real import. See Import::Gtfs::Shapes (especially Decorator)
  def import_without_status
    Rails.logger.info "Import #{source.num_records} records from the shapefile"
    source.each do |record|
      Rails.logger.info "Record number #{record.index}:"
      Rails.logger.info "  Geometry: #{record.geometry.as_text}"
      Rails.logger.info "  Attributes: #{record.attributes.inspect}"
    end
  ensure
    source.close
  end

  def shape_provider
    # Will be defined by the user in the future
    workbench.default_shape_provider
  end

  def source
    @source ||= Archive.new(local_file.path)
  end

  # Uses a temporary directory to open the user zip file and
  # make files readable.
  #
  # The zip file should contain entries like:
  #
  # * basename.cpg
  # * basename.dbf
  # * basename.prj
  # * basename.qpj
  # * basename.shp
  # * basename.shx
  class Archive

    # Tests if the given file looks like a zip file with shp/dbf/... files
    def self.valid?(file)
      Zip::File.open(file) do |zip_file|
        zip_file.glob('**/*.shp').size == 1
      end
    rescue => e
      Chouette::Safe.capture "Error in testing Shapefile file: #{file}", e
      return false
    end

    def initialize(file)
      @file = file
    end
    attr_reader :file

    def shp_file
      @shp_file ||= Dir.glob(File.join(temporary_directory, '**', '*.shp')).first
    end

    def temporary_directory
      @temporary_directory ||= open
    end

    # Creates a temporary directory and create the reader
    def open
      Dir.mktmpdir.tap do |directory|
        self.class.extract_zip file, directory
      end
    end

    MAX_FILES = 20
    MAX_FILE_SIZE = 100.megabytes

    def self.extract_zip(source_file, target_directory)
      Dir.chdir(target_directory) do
        Zip::File.open(source_file) do |file|
          files = 0
          file.each do |entry|
            files += 1 if entry.file?
            raise 'Too many extracted files' if files > MAX_FILES
            raise 'File too large when extracted' if entry.size > MAX_FILE_SIZE
            entry.extract
          end
        end
      end
    end

    def reader
      @reader ||= RGeo::Shapefile::Reader.open(shp_file)
    end

    delegate :each, :num_records, to: :reader

    def close
      if @temporary_directory
        FileUtils.remove_entry @temporary_directory
      end
    end

  end

end
