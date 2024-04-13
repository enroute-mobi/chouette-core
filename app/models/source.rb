require 'mimemagic_ext'
require 'net/ftp'

class Source < ApplicationModel
  extend Enumerize
  belongs_to :workbench, optional: false

  has_many :retrievals, class_name: "Source::Retrieval", foreign_key: "source_id", dependent: :destroy

  validates :name, presence: true
  validates :url, presence: true
  validates :downloader_type, presence: true
  validates :downloader_option_raw_authorization, presence: true, if: :authorization_downloader_type?

  #validates_associated :downloader

  enumerize :downloader_type, in: %i(direct french_nap authorization ftp), default: :direct

  scope :enabled, -> { where.not(retrieval_frequency: 'none') }

  before_validation :clean, on: :update

  attribute :retrieval_time_of_day, TimeOfDay::Type::TimeWithoutZone.new
  attribute :retrieval_days_of_week, WeekDays.new

  belongs_to :scheduled_job, class_name: '::Delayed::Job', dependent: :destroy
  validates :retrieval_time_of_day, presence: true, if: :retrieval_frequency_daily?
  validates :retrieval_days_of_week, presence: true, if: :enabled?

  enumerize :retrieval_frequency, in: %w[none hourly daily], default: 'none', predicates: { prefix: true }

  def enabled?
    !retrieval_frequency_none?
  end

  def next_retrieval
    return if retrieval_frequency_none?

    scheduled_job&.run_at
  end

  # ?? Rails 5 ActiveRecord::AttributeAssignment .. doesn't create an object
  # by invoke writer with multiparameter attributes (like {1 => 13, 2 => 15})
  def retrieval_time_of_day=(time_of_day)
    if time_of_day.is_a?(Hash) && time_of_day.keys == [1,2]
      time_of_day = TimeOfDay.new(time_of_day[1], time_of_day[2])
    end
    super time_of_day
  end

  def reschedule
    scheduled_job&.destroy
    schedule
  end

  def schedule
    return unless enabled?

    job = ScheduledJob.new(self)
    scheduled_job = Delayed::Job.enqueue(job, cron: job.cron)

    # To avoid a new save sequence
    update_column :scheduled_job_id, scheduled_job.id
  end

  # Reschedule and save the Source. Uses this method to force a rescheduling, in migration for example.
  def reschedule!
    reschedule
    save
  end

  def reschedule_needed?
    retrieval_frequency_changed? || retrieval_time_of_day_changed? || retrieval_days_of_week_changed?
  end

  def retrieval_days_of_week_attributes=(attributes)
    self.retrieval_days_of_week = Cuckoo::Timetable::DaysOfWeek.new(attributes)
  end

  # REMOVEME after CHOUETTE-2007
  before_validation ->(source) { source.retrieval_time_of_day ||= TimeOfDay.new(0, 0) }, if: :enabled?
  before_update :reschedule, if: :reschedule_needed?
  after_commit :schedule, on: :create, if: :enabled?

  # Uses to start the Source retrieval at the expected time
  class ScheduledJob
    def initialize(source)
      @source = source
      @source_id = source.id
    end
    attr_reader :source_id

    def encode_with(coder)
      coder['source_id'] = source_id
    end

    delegate :retrieval_time_of_day, :retrieval_frequency, :retrieval_days_of_week, to: :source

    def cron
      case retrieval_frequency
      when 'daily'
        if retrieval_time_of_day
          "#{retrieval_time_of_day.minute} #{retrieval_time_of_day.hour} * * #{retrieval_days_of_week_cron}"
        end
      when 'hourly'
        "#{hourly_random % 60} * * * #{retrieval_days_of_week_cron}"
      end
    end

    def retrieval_days_of_week_cron
      return '*' if retrieval_days_of_week.all?

      retrieval_days_of_week.days.map do |day_of_week|
        day_of_week.to_s.first(3)
      end.join(',')
    end

    def hourly_random
      source.id || Random.rand(60)
    end

    def source
      @source ||= Source.find_by(id: source_id)
    end

    def perform
      source.retrieve if source.enabled?
    rescue StandardError => e
      Chouette::Safe.capture "Can't start Source##{source_id} retrieval", e
    end
  end

  def authorization_downloader_type?
    downloader_type == 'authorization'
  end

  def clean
    unless downloader_type == "authorization"
      self.downloader_options = self.downloader_options.except("raw_authorization")
    end
  end

  def import_option_line_provider
    candidate_line_providers.find_by(id: import_option_line_provider_id) || workbench.default_line_provider
  end

  def import_option_stop_area_provider
    candidate_stop_area_providers.find_by(id: import_option_stop_area_provider_id) || workbench.default_stop_area_provider
  end

  def import_option_automatic_merge
    import_options["automatic_merge"]
  end

  def import_option_archive_on_fail
    import_options["archive_on_fail"]
  end

  def import_option_update_workgroup_providers
    import_options["update_workgroup_providers"]
  end

  def import_option_process_gtfs_route_ids
    (import_options["process_gtfs_route_ids"] || [])
  end

  def import_option_store_xml
    import_options["store_xml"]
  end

  def import_option_disable_missing_resources
    import_options["disable_missing_resources"]
  end

  def import_option_strict_mode
    import_options["strict_mode"]
  end

  def import_option_line_provider_id
    import_options["line_provider_id"]
  end

  def import_option_stop_area_provider_id
    import_options["stop_area_provider_id"]
  end

  def import_option_automatic_merge=(value)
    import_options["automatic_merge"] = value
  end

  def import_option_archive_on_fail=(value)
    import_options["archive_on_fail"] = value
  end

  def import_option_update_workgroup_providers=(value)
    import_options["update_workgroup_providers"] = value
  end

  # Use compact to delete empty value
  def import_option_process_gtfs_route_ids=(value)
    import_options["process_gtfs_route_ids"] = value.reject(&:blank?)
  end

  def import_option_store_xml=(value)
    import_options["store_xml"] = value
  end

  def import_option_disable_missing_resources=(value)
    import_options["disable_missing_resources"] = value
  end

  def import_option_strict_mode=(value)
    import_options["strict_mode"] = value
  end

  def import_option_line_provider_id=(value)
    import_options["line_provider_id"] = value
  end

  def import_option_stop_area_provider_id=(value)
    import_options["stop_area_provider_id"] = value
  end

  def update_workgroup_providers?
    import_options["update_workgroup_providers"] == "true"
  end

  def store_xml?
    import_options["store_xml"] == "true"
  end

  def disable_missing_resources?
    import_options["disable_missing_resources"] == "true"
  end

  def downloader_option_raw_authorization
    downloader_options["raw_authorization"]
  end

  def downloader_option_raw_authorization=(value)
    downloader_options["raw_authorization"] = value
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
    retrieval = retrievals.create(creator: 'Source')
    retrieval.enqueue
    retrievals.delete_older
  end

  delegate :line_providers, :stop_area_providers, to: :workbench, prefix: :candidate

  module Downloader

    class Base
      attr_reader :url

      def initialize(url, options = {})
        @url = url
        options.each { |k,v| send "#{k}=", v }
      end
    end
    class URL < Base
      mattr_accessor :timeout, default: 120.seconds

      def download(path, headers = {})
        Fetcher.new(url, headers, read_timeout: timeout).fetch(path)
      end
    end

    # Downlaod a given URL. Manages redirection
    class Fetcher

      attr_reader :url, :headers
      attr_accessor :read_timeout
      attr_writer :redirection_count

      def initialize(url, headers = {}, options = {})
        @url = url
        @headers = headers

        options.each { |k, v| send "#{k}=", v }
      end

      def request
        @request ||= Net::HTTP::Get.new(uri).tap do |request|
          headers.each { |name, value| request[name] = value }
        end
      end

      def response
        http.start do |http|
          http.request request
        end
      end

      def uri
        @uri ||= URI(url)
      end

      def use_ssl?
        uri.instance_of?(URI::HTTPS)
      end

      def http
        Net::HTTP.new(uri.hostname, uri.port).tap do |http|
          http.use_ssl = use_ssl?
          http.read_timeout = read_timeout if read_timeout
        end
      end

      def error_for(response) # rubocop:disable Metrics/MethodLength
        Rails.logger.debug { "HTTP response: #{response.code} #{response.body}" }
        message_key =
          # TODO: we should/could test the response class
          case response.code
          when '404'
            :url_not_found
          when '401', '403'
            :authentication_failed
          when /^50\d$/
            :url_not_available
          else
            :download_failed
          end
        Source::Retrieval::Error.new message_key
      end

      def redirection_count
        @redirection_count ||= 10
      end

      def allow_redirect?
        redirection_count > 1
      end

      def redirect
        raise Source::Retrieval::Error, :url_not_available unless allow_redirect?

        Fetcher.new(response['location'], headers, redirection_count: redirection_count - 1)
      end

      def fetch(path)
        http.start do |http|
          http.request request do |response|
            return redirect.fetch(path) if response.is_a?(Net::HTTPRedirection)
            raise error_for(response) unless response.is_a?(Net::HTTPSuccess)

            File.open(path, 'wb') do |file|
              response.read_body file
            end
          end
        end
      end
    end

    class FrenchNap < Base
      def download(path)
        URL.new(link).download(path)
      end

      def page
        # FIXME: this download should be protected
        Nokogiri::HTML(URI.open(url))
      end

      def link
        # New layout : some download links are in a "div.resource-actions" class element, others just in a table
        # We prefer to use table links because we have absolute url and never relative url
        l = page.css('table')
        l.css('a').first["href"]
      end
    end

    class Authorization < Base
      attr_accessor :raw_authorization
      #validates_presence_of :raw_authorization

      def download(path)
        URL.new(url).download(path, headers)
      end

      private

      def headers
        return {} unless raw_authorization

        { 'Authorization' => raw_authorization }
      end
    end

    class Ftp < Base

      def download(path)
        ftp.getbinaryfile(remote_filename, path)
      end

      def uri
        @uri ||= URI(url)
      end

      def host
        @host ||= uri.host
      end

      def port
        @port ||= uri.port
      end

      def username
        @username ||= (uri.user || 'anonymous')
      end

      def password
        @password ||= (uri.password || 'chouette@enroute.mobi')
      end

      def remote_dir
        @remote_dir ||= File.dirname uri.path
      end

      def remote_filename
        @remote_filename ||= File.basename uri.path
      end

      def ftp
        @ftp ||= Net::FTP.new.tap do |ftp|
          ftp.connect host, port
          ftp.login username, password
          ftp.chdir remote_dir
          ftp.passive = true
        end
      end
    end
  end

  module Checksumer
    def self.for(type)
      type.zip? ? ZIP : File
    end

    class File
      include Measurable

      attr_reader :file
      def initialize(file)
        @file = file
      end

      def digest
        @digest ||= Digest::SHA256.new
      end

      def checksum
        checksum!
        digest.hexdigest
      end

      protected

      def digest_stream(io)
        buffer = ""
        while io.read 16384, buffer
          digest.update buffer
        end
      end

      def checksum!
        ::File.open(file) do |file|
          digest_stream file
        end
      end
    end

    class ZIP < File
      MAX_SIZE = 1024.megabytes

      # Digest entries name and content
      # Don't use a Zip::InputStream to avoid difference with entry order change
      def checksum!
        ::Zip::File.open(file) do |zip_file|
          # Sort the entries by name to always digest in the same order
          zip_file.glob('*').sort_by(&:name).each do |entry|
            # We could read only the beginning of larger files
            raise 'File too large when extracted' if entry.size > MAX_SIZE

            next unless entry.file?

            # Digest the entry name
            digest.update entry.name
            # Digest the entry content
            digest_stream entry.get_input_stream
          end
        end
      end
    end
  end

  class Retrieval < Operation
    include Measurable

    belongs_to :source, optional: false
    belongs_to :import, class_name: "Import::Workbench"
    belongs_to :workbench, optional: false

    before_validation :set_workbench, on: :create
    delegate :workgroup, to: :workbench

    attr_accessor :source_error

    def perform
      unless source
        logger.info "Source #{source_id} no longer available"
        return
      end

      download
      process
      # We could add an option to ignore the checksum / force the import
      if checksum_changed?
        logger.info "Checksum has changed"

        create_import
        source.update checksum: checksum
        self.message_key = :new_content_detected
      else
        self.message_key = :no_import_required
        logger.info "Checksum unchanged. Import is skipped"
      end
    rescue Source::Retrieval::Error => e
      logger.info "Retrieval failed with user message: #{e.message_key}"
      self.message_key = e.message_key
      self.source_error = e
    ensure
      save
    end

    def final_user_status
      return Operation.user_status.failed if source_error
      super
    end

    delegate :downloader, :import_options, to: :source

    def downloaded_file
      @downloaded_file ||= Tempfile.new(["retrieval-downloaded"])
    end

    def download
      logger.info "Download with #{downloader.class}"
      downloader.download downloaded_file
    end
    measure :download

    def user_message
      return '-' unless message_key
      I18n.translate message_key, scope: 'source/retrieval.user_message'
    end

    # To be replaced by import features (line selection, ignore parents, etc)
    def process
      return unless processor
      logger.info "Process downloaded file"
      processor.process downloaded_file, processed_file
    end
    measure :process

    def processor
      Processor::GTFS.new.with_options(processing_options).presence || Processor::Copy.new
    end

    class Error < StandardError
      attr_reader :message_key

      def initialize(message_key = nil)
        super(nil)

        @message_key = message_key
      end
    end

    def processed_file
      @processed_file ||= Tempfile.new(["retrieval-processed",".#{downloaded_file_type.default_extension}"])
    end

    def import_name
      "#{source.name} #{I18n.l(Time.zone.today)}"
    end

    def imported_file
      @processed_file || downloaded_file
    end

    def downloaded_file_type
      @file_type ||= MimeMagic.by_magic(downloaded_file)
    end

    def checksumer_class
      Checksumer.for(downloaded_file_type)
    end

    def checksumer
      checksumer_class.new imported_file
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
        options: import_workbench_options,
        type: 'Import::Workbench',
        import_category: import_category
      }
    end

    def create_import
      update import: workbench.imports.create!(import_attributes)
    end

    def self.delete_older(offset=20)
      order(created_at: :desc).offset(offset).delete_all
    end

    def import_workbench_options
      import_options
        .merge(import_category_option)
        .except(*processing_options.keys)
    end

    def processing_options
      import_options.select{ |key, _| key.start_with?('process_') }
    end

    def import_category_option
      if downloaded_file_type&.xml?
        { import_category: "netex_generic" }
      else
        {}
      end
    end

    def import_category
      "netex_generic" if downloaded_file_type&.xml?
    end

    private

    def set_workbench
      self.workbench = self.source&.workbench
    end
  end

  module Processor
    class Copy
      def process(source_file, target_file)
        IO.copy_stream(source_file, target_file)
      end
    end

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
