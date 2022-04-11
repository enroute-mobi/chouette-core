class Source < ApplicationModel
  extend Enumerize
  belongs_to :workbench, optional: false

  has_many :retrievals, class_name: "Source::Retrieval", foreign_key: "source_id", dependent: :destroy

  validates :name, presence: true
  validates :url, presence: true
  validates :downloader_type, presence: true

  enumerize :downloader_type, in: %i(direct french_nap), default: :direct

  scope :enabled, -> { where enabled: true }

  def import_option_automatic_merge
    import_options["automatic_merge"]
  end

  def import_option_archive_on_fail
    import_options["archive_on_fail"]
  end

  def import_option_automatic_merge=(value)
    import_options["automatic_merge"] = value
  end

  def import_option_archive_on_fail=(value)
    import_options["archive_on_fail"] = value
  end

  def self.retrieve_all
    find_each do |source|
      source.retrieve
    end
  end

  def downloader_class
    if downloader_type.present? && downloader_type != :direct
      Downloader.const_get(downloader_type.camelcase)
    else
      Downloader::URL
    end
  end

  def downloader
    downloader_class.new url, downloader_options
  end

  def retrieve
    if enabled
      retrieval = retrievals.create(creator: "Source")
      retrieval.enqueue
      retrievals.delete_older
    end
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

    class FrenchNap < Base
      def download(path)
        URL.new(link).download(path)
      end

      def page
        Nokogiri::HTML(open(url))
      end

      def link
        # New layout : some download links are in a "div.resource-actions" class element, others just in a table
        # We prefer to use table links because we have absolute url and never relative url
        l = page.css('table')
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

  class Retrieval < Operation
    include Measurable

    belongs_to :source, optional: false
    belongs_to :import, class_name: "Import::Workbench"
    belongs_to :workbench, optional: false

    before_validation :set_workbench, on: :create
    delegate :workgroup, to: :workbench

    def perform
      download
      process

      # We could add an option to ignore the checksum / force the import
      if checksum_changed?
        logger.info "Checksum has changed"

        create_import
        source.update checksum: checksum
      else
        logger.info "Checksum unchanged. Import is skipped"
      end
    end

    delegate :downloader, :import_options, to: :source

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
      source.ignore_checksum || (source.checksum != checksum)
    end

    def import_attributes
      {
        name: import_name,
        creator: creator,
        file: imported_file,
        options: import_options,
        type: "Import::Workbench"
      }
    end

    def create_import
      update import: workbench.imports.create!(import_attributes)
    end

    def self.delete_older(offset=20)
      order(created_at: :desc).offset(offset).delete_all
    end

    private

    def set_workbench
      self.workbench = self.source&.workbench
    end
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
        ignore_parents = self.ignore_parents?

        gtfs_target_for = Proc.new do |resource, associations|
          ignored = false

          if route_ids.present?
            ignored = (route_ids & associations[:route_ids]).empty?
          end

          if ignore_parents && !ignored && resource.is_a?(::GTFS::Stop)
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
