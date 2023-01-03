module LocalImportSupport
  extend ActiveSupport::Concern

  included do |_into|
    include ImportResourcesSupport
    after_commit :import_async, on: :create, unless: :profile?

    delegate :line_referential, :stop_area_referential, to: :workbench
  end

  module ClassMethods
    def profile(filepath, profile_options = {})
      import = new(creator: 'Profiler', workbench: Workbench.first)
      import.file = File.open(filepath)
      import.profile = true
      import.profile_options = profile_options
      import.name = "Profile #{File.basename(filepath)}"
      import.save!
      import.reload
      if profile_options[:operations]
        if profile_options[:reuse_referential]
          r = if profile_options[:reuse_referential].is_a?(Referential)
                profile_options[:reuse_referential]
              else
                Referential.where(name: import.referential_name).last
              end
          import.referential = r
          r.switch
        else
          import.create_referential
        end
      end
      import.save!
      if profile_options[:operations]
        import.profile_tag 'import' do
          ActiveRecord::Base.cache do
            import.import_resources(*profile_options[:operations])
          end
        end
      else
        import.import
      end
      import
    end
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

      processing_rules.each do |processing_rule|
        if processing_rule.use_control_list?
          processed = processing_rule.processable.control_list_runs.new(name: processing_rule.processable.name,
                                                                        creator: 'Webservice',
                                                                        referential: referential,
                                                                        workbench: workbench
                                                                      )
          processed.build_with_original_control_list
        else
          processed = processing_rule.processable.macro_list_runs.new(name: processing_rule.processable.name,
                                                                      creator: 'Webservice', referential: referential)
          processed.build_with_original_macro_list
        end

        processing = processing_rule.processings.create step: :after, operation: self, workbench_id: processing_rule.workbench_id,
                                                        workgroup_id: processing_rule.workgroup_id, processed: processed

        break unless processing.perform
      end

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
        message_key: 'referential_creation_overlapping_existing_referential',
        message_attributes: {
          referential_name: referential.name,
          overlapped_name: overlapped.name,
          overlapped_url: Rails.application.routes.url_helpers.referential_path(overlapped)
        }
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

  def processing_rules
    # Returns Processing Rules associated to Import operation with a specific order:
    #   Macro List first
    #   Control List
    #   Workgroup Control List
    workbench_processing_rules + workgroup_processing_rules
  end

  def workbench_processing_rules
    workbench.processing_rules.where(operation_step: 'after_import').order(processable_type: :desc)
  end

  def workgroup_processing_rules
    dedicated_processing_rules = workbench.workgroup.processing_rules.where(operation_step: 'after_import',
                                                                  target_workbench_ids: [workbench_id])
    return dedicated_processing_rules if dedicated_processing_rules.present?
      
    workbench.workgroup.processing_rules.where(operation_step: 'after_import', target_workbench_ids: [])
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

  def create_referential
    Chouette::Benchmark.measure 'create_referential' do
      self.referential ||= Referential.new(
        name: referential_name,
        organisation_id: workbench.organisation_id,
        workbench_id: workbench.id,
        metadatas: [referential_metadata],
        ready: false
      )

      Referential.find(self.referential.overlapped_referential_ids).each(&:archive!) if profile?
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

    Rails.logger.info "#{self.class.name} ##{id}: invoke next_step"
    next_step

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
    profile_tag "save_model.#{model.class.name}" do
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
