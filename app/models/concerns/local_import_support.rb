# frozen_string_literal: true

module LocalImportSupport
  extend ActiveSupport::Concern

  included do |_into|
    include ImportResourcesSupport
    after_commit :import_async, on: :create

    delegate :line_referential, :stop_area_referential, to: :workbench
  end

  def import_async
    enqueue_job :import
  end

  def import_type
    self.class.name.demodulize.underscore
  end

  def import
    Chouette::Benchmark.measure "import_#{import_type}", id: id do
      update status: 'running', started_at: Time.now
      @progress = 0

      ActiveRecord::Base.cache do
        import_without_status
      end

      processor.after([referential])

      @progress = nil
      @status ||= 'successful'
      referential&.active!
      update status: @status, ended_at: Time.now
    end
  rescue StandardError => e
    update status: 'failed', ended_at: Time.now
    Chouette::Safe.capture "#{self.class.name} ##{id} failed", e

    if (referential && overlapped_referential_ids = referential.overlapped_referential_ids).present?
      overlapped = Referential.find overlapped_referential_ids.last
      create_message(
        criticity: :error,
        message_attributes: {
          referential_name: referential.name,
          overlapped_name: overlapped.name,
          overlapped_url: Rails.application.routes.url_helpers.workbench_referential_path(workbench, overlapped)
        },
        message_key: 'referential_creation_overlapping_existing_referential'
      )
    else
      create_message criticity: :error, message_key: :full_text, message_attributes: { text: e.message }
    end
    referential&.failed!
  ensure
    main_resource&.save
    save
    notify_parent
  end

  def processor
    @processor ||= Processor.new(self)
  end

  def worker_died
    force_failure!

    Rails.logger.error "#{self.class.name} #{inspect} failed due to worker being dead"
  end

  def import_resources(*resources)
    resources.each do |resource|
      Chouette::Benchmark.measure resource do
        send "import_#{resource}"
      end
    end
  end

  def referential_builder
    @referential_builder ||= ReferentialBuilder.new(workbench, name: referential_name, metadata: referential_metadata)
  end

  # Create a Referential with given name and medata
  class ReferentialBuilder
    def initialize(workbench, name:, metadata:)
      @workbench = workbench
      @name = name
      @metadata = metadata
    end
    attr_reader :workbench, :name, :metadata

    delegate :organisation, to: :workbench

    def create(&block)
      if valid?
        Rails.logger.debug "Create imported Referential: #{referential.inspect}"
        block.call referential
      else
        Rails.logger.debug "Can't created imported Referential: #{referential.inspect}"
      end
    end

    def referential
      @referential ||= workbench.referentials.create(
        name: name,
        organisation: organisation,
        metadatas: [metadata],
        ready: false
      )
    end

    def valid?
      @valid ||= referential.valid?
    end

    def overlapping_referential_ids
      @overlapping_referential_ids ||= referential.overlapped_referential_ids
    end
  end

  def create_referential
    Chouette::Benchmark.measure 'create_referential' do
      self.referential ||= referential_builder.referential

      begin
        self.referential.save!
      rescue ActiveRecord::RecordInvalid
        # No double capture for Chouette::Safe
        Rails.logger.error "Unable to create referential: #{self.referential.errors.messages}"
        raise
      end
      main_resource.update referential: referential if main_resource
    end
  end

  def referential_name
    name.presence || File.basename(local_file.to_s)
  end

  def notify_parent
    Rails.logger.info "#{self.class.name} ##{id}: notify_parent #{caller[0..2].inspect}"

    main_resource&.update_status_from_importer status

    super
  end

  attr_accessor :local_file, :download_host

  def local_file
    @local_file ||= download_local_file
  end

  def download_host
    @download_host ||= Rails.application.config.rails_host
  end

  def local_temp_directory
    @local_temp_directory ||=
      begin
        directory = Rails.application.config.try(:import_temporary_directory) || Rails.root.join('tmp', 'imports')
        FileUtils.mkdir_p directory
        directory
      end
  end

  def local_temp_file
    file = Tempfile.open('chouette-import', local_temp_directory)
    file.binmode
    yield file
  end

  def download_path
    # FIXME: See CHOUETTE-205
    Rails.application.routes.url_helpers.internal_download_workbench_import_path(workbench, id, token: token_download)
  end

  def download_uri
    @download_uri ||=
      begin
        host = download_host
        host = "http://#{host}" unless host =~ %r{https?://}
        URI.join(host, download_path)
      end
  end

  def download_local_file
    local_temp_file do |file|
      Net::HTTP.start(download_uri.host, download_uri.port) do |http|
        http.request_get(download_uri.request_uri) do |response|
          response.read_body do |segment|
            file.write segment
          end
        end
      end

      file.rewind
      file
    end
  end

  def save_model(model, filename: nil, line_number: nil, column_number: nil, resource: nil)
    return unless model.changed?

    if resource
      filename ||= "#{resource.name}.txt"
      line_number ||= resource.rows_count
      column_number ||= 0
    end

    unless model.save
      Rails.logger.error "Can't save #{model.class.name} : #{model.errors.inspect}"

      # if the model cannot be saved, we still ensure we store a consistent checksum
      model.try(:update_checksum_without_callbacks!) if model.persisted?

      model.errors.details.each do |key, messages|
        messages.uniq.each do |message|
          message.each do |criticity, error|
            next unless Import::Message.criticity.values.include?(criticity.to_s)

            create_message(
              {
                criticity: criticity,
                message_key: error,
                message_attributes: {
                  test_id: key,
                  object_attribute: key,
                  source_attribute: key
                },
                resource_attributes: {
                  filename: filename,
                  line_number: line_number,
                  column_number: column_number
                }
              },
              resource: resource,
              commit: true
            )
          end
        end
      end
      @models_in_error ||= Hash.new { |hash, key| hash[key] = [] }
      @models_in_error[model.class.name] << model_key(model)
      @status = 'failed'
      return
    end

    Rails.logger.debug "Created #{model.inspect}"
  end

  def check_parent_is_valid_or_create_message(klass, key, resource)
    if @models_in_error&.key?(klass.name) && @models_in_error[klass.name].include?(key)
      create_message(
        {
          criticity: :error,
          message_key: :invalid_parent,
          message_attributes: {
            parent_class: klass,
            parent_key: key,
            test_id: :parent
          },
          resource_attributes: {
            filename: "#{resource.name}.txt",
            line_number: resource.rows_count,
            column_number: 0
          }
        },
        resource: resource, commit: true
      )
      return false
    end
    true
  end

  def unless_parent_model_in_error(klass, key, resource)
    return unless check_parent_is_valid_or_create_message(klass, key, resource)

    yield
  end

  def model_key(model)
    return model.registration_number if model.respond_to?(:registration_number)

    return model.comment if model.is_a?(Chouette::TimeTable)
    return model.checksum_source if model.is_a?(Chouette::VehicleJourneyAtStop)

    model.objectid
  end
end
