class WorkbenchImportService
  include Rails.application.routes.url_helpers

  include ObjectStateUpdater

  attr_reader :entries, :workbench_import

  class << self
    attr_accessor :import_dir
  end

  def logger
    Rails.logger
  end

  def perform(import_id)
    @entries = 0
    import_id = import_id.id if import_id.is_a?(ActiveRecord::Base)
    @workbench_import ||= Import::Workbench.find(import_id)

    zip_service = ZipService.new(downloaded, allowed_lines)
    upload zip_service
  rescue Zip::Error
    handle_corrupt_zip_file
  rescue => e
    Chouette::Safe.capture "WorkbenchImportService ##{import_id} failed", e
    workbench_import.update_columns status: 'failed'
  ensure
    workbench_import.update_columns ended_at: Time.now
  end

  def execute_post eg_name, eg_file
    logger.info "HTTP POST #{export_url} (for #{complete_entry_group_name(eg_name)}, file #{eg_file} #{File.size(eg_file)})"
    HTTPService.post_resource(
      host: export_host,
      path: export_path,
      params: params(eg_file, eg_name),
      token: Rails.application.secrets.api_token)
  end

  def handle_corrupt_zip_file
    workbench_import.messages.create(criticity: :error, message_key: 'corrupt_zip_file', message_attributes: {source_filename: workbench_import.file.file.file})
    workbench_import.update( current_step: @entries, status: 'failed' )
  end

  def upload zip_service
    entry_group_streams = zip_service.subdirs
    if entry_group_streams.many?
      workbench_import.messages.create(criticity: :error, message_key: 'several_datasets')
      workbench_import.update status: 'failed'
      return
   end
    entry_group_streams.each_with_index(&method(:upload_entry_group))
    workbench_import.update total_steps: @entries
    handle_corrupt_zip_file unless @subdir_uploaded
  rescue Exception => e
    Chouette::Safe.capture "Upload failed", e
    workbench_import.update( current_step: @entries, status: 'failed' )
    raise
  end

  def upload_entry_group entry, element_count
    @subdir_uploaded = true
    update_object_state entry, element_count.succ
    unless entry.ok?
      workbench_import.update current_step: @entries
      workbench_import.failed!
      return
    end
    # status = retry_service.execute(&upload_entry_group_proc(entry))
    upload_entry_group_stream entry.name, entry.stream
  end

  def upload_entry_group_stream eg_name, eg_stream
    eg_stream.rewind

    result = nil
    Tempfile.open do |temp_file|
      temp_file.write eg_stream.read
      temp_file.close
      result = execute_post eg_name, temp_file.path
    end

    if result && result.status < 400
      @entries += 1
      workbench_import.update( current_step: @entries )
      result
    else
      raise StopIteration, result.body
    end
  end

  # Queries
  # =======

  def complete_entry_group_name entry_group_name
    [workbench_import.name, entry_group_name].join("--")
  end

  # Constants
  # =========

  def export_host
    Rails.application.config.rails_host
  end
  def export_path
    api_v1_internals_netex_imports_path(format: :json)
  end
  def export_url
    @__export_url__ ||= File.join(export_host, export_path)
  end

  def import_host
    Rails.application.config.rails_host
  end
  def import_path
    # FIXME See CHOUETTE-205
    @__import_path__ ||= internal_download_workbench_import_path(workbench_import.workbench, workbench_import)
  end
  def import_url
    @__import_url__ ||= File.join(import_host, import_path)
  end

  def params file, name
    { netex_import:
      { parent_id: workbench_import.id,
        parent_type: workbench_import.class.name,
        workbench_id: workbench_import.workbench_id,
        name: name,
        file: HTTPService.upload(file, 'application/zip', "#{name}.zip") } }
  end

  # Lazy Values
  # ===========

  def allowed_lines
    # We need local ids ('C02141' for 'FR1:Line:C02141:')
    @__allowed_lines__ ||= workbench_import.workbench.lines.map(&:code)
  end
  def downloaded
    @__downloaded__ ||= download_response.body
  end
  def download_response
    @__download_response__ ||= HTTPService.get_resource(
      host: import_host,
      path: import_path,
      params: {token: workbench_import.token_download}).tap do
        logger.info  "HTTP GET #{import_url}"
      end
  end
end
