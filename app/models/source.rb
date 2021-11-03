class Source < ApplicationModel
  belongs_to :workbench, optional: false
  validates :name, presence: true
  validates :url, presence: true

  def self.retrieve_all
    find_each do |source|
      source.retrieve
    end
  end

  def downloader_class
    if downloader_type.present?
      Downloader.const_get(downloader_type)
    else
      Downloader::URL
    end
  end

  def downloader
    downloader_class.new url, downloader_options
  end

  def retrieve
    Retrieval.new(self).perform
  end

  module Downloader
    class Base
      attr_reader :url

      def initialize(url, options = {})
        @url = url
        options.each { |k,v| send "#{k}=", v }
      end
    end

    class URL < Base
      def download(path)
        File.open(path, "wb") do |file|
          IO.copy_stream open(url), file
        end
      end
    end

    class FrenchNAP < Base
      def download(path)
        URL.new(link).download(path)
      end

      def page
        Nokogiri::HTML(open(url))
      end

      def link
        # New layout : some download links are in a "resource--download" class element, others just in a table
        l = page.css('div.resource--download')
        l = page.css('table') if l.empty?
        l.css('a').first["href"]
      end
    end
  end

  module Checksumer
    class Zip
      include Measurable

      attr_reader :file
      def initialize(file)
        @file = file
      end

      MAX_SIZE = 512.megabytes

      # Digest entries name and content
      # Don't use a Zip::InputStream to avoid difference with entry order change
      def checksum
        digest = Digest::SHA256.new

        ::Zip::File.open(@file) do |zip_file|
          # Sort the entries by name to always digest in the same order
          zip_file.glob('*').sort_by(&:name).each do |entry|
            # We could read only the beginning of larger files
            raise 'File too large when extracted' if entry.size > MAX_SIZE

            # Digest the entry name
            digest.update entry.name

            # Digest the entry content
            buffer = ""
            io = entry.get_input_stream
            while io.read 16384, buffer
              digest.update buffer
            end
          end
        end

        digest.hexdigest
      end
      measure :checksum

    end
  end

  class Retrieval # < Operation
    attr_reader :source
    def initialize(source)
      @source = source
    end

    include Measurable
    def uuid
      @uuid ||= SecureRandom.uuid
    end

    def logger
      Rails.logger
    end

    def perform
      # The Operation base code should manage logger, uuid, status, error, include measurable, etc
      logger.tagged("Retrieval ##{uuid}") do
        measure "retrieval", source_id: source.id do
          logger.info "Retrieve Source ##{source.id}"
          begin
            download
            process

            # We could add an option to ignore the checksum / force the import
            if checksum_changed?
              logger.info "Checksum has changed"
              import
              source.update checksum: checksum
            else
              logger.info "Checksum unchanged. Import is skipped"
            end
          rescue => e
            Chouette::Safe.capture "Failed to retrieve #{source.inspect}",e
          end
        end
      end
    end

    delegate :downloader, :import_options, :workbench, to: :source

    def downloaded_file
      @downloaded_file ||= Tempfile.new(["retrieval-downloaded", ".zip"])
    end

    def download
      logger.info "Download with #{downloader.class}"
      downloader.download downloaded_file
    end
    measure :download

    # To be replaced by import features (line selection, ignore parents, etc)
    def process
      return unless processor
      logger.info "Process downloaded file"
      processor.process downloaded_file, processed_file
    end
    measure :process

    def processor
      Processor::GTFS.new.with_options(import_options).presence
    end

    def processed_file
      @processed_file ||= Tempfile.new(["retrieval-processed",".zip"])
    end

    def import_name
      "#{source.name} #{I18n.l(Time.zone.today)}"
    end

    def imported_file
      @processed_file || downloaded_file
    end

    def checksumer
      Checksumer::Zip.new imported_file
    end

    def checksum
      @checksum ||= checksumer.checksum
    end

    def checksum_changed?
      source.checksum != checksum
    end

    def import
      import = Import::Workbench.create!(workbench: workbench, name: import_name, creator: "Source", file: imported_file, options: import_options)
      logger.info "Started Import #{import.id}"
    end
    measure :import

  end

  module Processor
    class GTFS

      def with_options(options = {})
        @route_ids = options["process_gtfs_route_ids"]
        @ignore_parents = options["process_gtfs_ignore_parents"]

        self
      end

      def route_ids
        @route_ids ||= []
      end

      def ignore_parents?
        @ignore_parents
      end

      def empty?
        route_ids.empty? && !ignore_parents?
      end

      def process(source_file, target_file)
        route_ids = self.route_ids

        gtfs_target_for = Proc.new do |resource, associations|
          ignored = (route_ids & associations[:route_ids]).empty?

          if !ignored && resource.is_a?(::GTFS::Stop)
            resource.parent_station = nil
            ignored = true if resource.station?
          end

          if ignored
            void_target
          else
            target(target_file)
          end
        end

        ::GTFS::Rewriter.new(source_file, target_for: gtfs_target_for).rewrite
      end
    end
  end
end
