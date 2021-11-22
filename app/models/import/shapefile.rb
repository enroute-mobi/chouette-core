# Imports Shapes defined into a 'zip' Shapefile in the Workbench ShapeReferential
class Import::Shapefile < Import::Base
  include LocalImportSupport
  include Measurable
  include Imports::WithoutReferentialSupport

  # Used by Import::Workbench to test the imported file
  def self.accepts_file?(file)
    Archive.valid? file
  end

  def import_without_status
    begin
      index = 0
      # TODO manage automatic id attribute detection if shape_attribute_as_id blank
      shape_attribute_as_id = parent.shape_attribute_as_id
      raise UnprovidedIdAttributeError unless shape_attribute_as_id

      Shape.transaction do
        source.each do |record|
          raise WrongIdAttributeError unless record.attributes.has_key? shape_attribute_as_id
          raise EmptyLineStringError if record.geometry.num_geometries == 0
          raise MultiLineStringError if record.geometry.num_geometries > 1

          code_value = record.attributes[shape_attribute_as_id]

          shape_attributes = {
            geometry: record.geometry.geometry_n(0),
            shape_provider: shape_provider
          }

          shape = shape_provider.shapes.by_code(code_space, code_value).first
          if shape
            shape.update shape_attributes
          else
            shape = shape_provider.shapes.build shape_attributes
            shape.codes.build code_space: code_space, value: code_value
            shape.save
          end
          index+=1
        end
      end
    rescue Import::Shapefile::UnprovidedIdAttributeError, Import::Shapefile::EmptyLineStringError, Import::Shapefile::MultiLineStringError, RGeo::Error::InvalidGeometry => e
      message_key = case e
      when Import::Shapefile::UnprovidedIdAttributeError
        'shapefile_unprovided_id_attribute'
      when Import::Shapefile::EmptyLineStringError
        'shapefile_empty_linestring'
      when Import::Shapefile::MultiLineStringError
        'shapefile_more_than_one_linestring'
      when RGeo::Error::InvalidGeometry
        index+=1
        'shapefile_geometry_parsing_error'
      end

      create_message(
        {
          criticity: :error,
          message_key: message_key,
          message_attributes: {
            shape_index: index
          }
        },
        commit: true
      )
      @status = 'failed'
    rescue Import::Shapefile::WrongIdAttributeError
      create_message(
        {
          criticity: :error,
          message_key: 'shapefile_wrong_id_attribute',
          message_attributes: {
            shape_attribute: shape_attribute_as_id
          }
        },
        commit: true
      )
      @status = 'failed'
    end
  ensure
    source.close
  end

  class UnprovidedIdAttributeError < StandardError; end
  class WrongIdAttributeError < StandardError; end
  class EmptyLineStringError < StandardError; end
  class MultiLineStringError < StandardError; end


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
      @reader ||= RGeo::Shapefile::Reader.open(shp_file,{srid: 4326})
    end

    delegate :each, :num_records, to: :reader

    def close
      if @temporary_directory
        FileUtils.remove_entry @temporary_directory
      end
    end

  end

end
