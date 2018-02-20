class WorkbenchImportWorker
  include Sidekiq::Worker
  include Rails.application.routes.url_helpers
  include Configurable

  include ObjectStateUpdater

  attr_reader :entries, :workbench_import

  # Workers
  # =======

  def perform(import_id)
    @entries = 0
    @workbench_import ||= WorkbenchImport.find(import_id)

    workbench_import.update(status: 'running', started_at: Time.now)
    zip_service = ZipService.new(downloaded, allowed_lines)
    upload zip_service
    workbench_import.update(ended_at: Time.now)
  rescue Zip::Error
    handle_corrupt_zip_file
  end

  def execute_post eg_name, eg_file
    logger.info  "HTTP POST #{export_url} (for #{complete_entry_group_name(eg_name)})"
    HTTPService.post_resource(
      host: export_host,
      path: export_path,
      params: params(eg_file, eg_name))
  end

  def handle_corrupt_zip_file
    workbench_import.messages.create(criticity: :error, message_key: 'corrupt_zip_file', message_attributes: {source_filename: workbench_import.file.file.file})
  end

  def upload zip_service
    entry_group_streams = zip_service.subdirs
    entry_group_streams.each_with_index(&method(:upload_entry_group))
    workbench_import.update total_steps: @entries
  rescue Exception => e
    logger.error e.message
    workbench_import.update( current_step: @entries, status: 'failed' )
    raise
  end


  def upload_entry_group entry, element_count
    update_object_state entry, element_count.succ
    return unless entry.ok?
    # status = retry_service.execute(&upload_entry_group_proc(entry))
    upload_entry_group_stream entry.name, entry.stream
  end

  def upload_entry_group_stream eg_name, eg_stream
    FileUtils.mkdir_p(temp_directory)

    eg_file_path = Tempfile.open(
      ["WorkbenchImport_#{eg_name}_", '.zip'],
      temp_directory
    ) do |f|
      eg_stream.rewind
      f.write eg_stream.read

      f.path
    end

    eg_file = File.open(eg_file_path)

    result = execute_post eg_name, eg_file
    if result && result.status < 400
      @entries += 1
      workbench_import.update( current_step: @entries )
      result
    else
      raise StopIteration, result.body
    end
  ensure
    eg_file.close rescue nil
    eg_file.unlink rescue nil
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
    api_v1_netex_imports_path(format: :json)
  end
  def export_url
    @__export_url__ ||= File.join(export_host, export_path)
  end

  def import_host
    Rails.application.config.rails_host
  end
  def import_path
    @__import_path__ ||= download_workbench_import_path(workbench_import.workbench, workbench_import)
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

  def temp_directory
    Rails.application.config.try(:import_temporary_directory) ||
      Rails.root.join('tmp', 'imports')
  end

  # Lazy Values
  # ===========

  def allowed_lines
    @__allowed_lines__ ||= workbench_import.workbench.organisation.lines_set
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
