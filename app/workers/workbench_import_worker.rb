class WorkbenchImportWorker
  include Sidekiq::Worker
  include Rails.application.routes.url_helpers
  include Configurable

  # Workers
  # =======

  def perform(import_id)
    @workbench_import = WorkbenchImport.find(import_id)
    @response         = nil
    @workbench_import.update(status: 'running', started_at: Time.now)
    downloaded  = download
    zip_service = ZipService.new(downloaded)
    upload zip_service
    @workbench_import.update(ended_at: Time.now)
  end

  def download
    logger.info  "HTTP GET #{import_url}"
    @zipfile_data = HTTPService.get_resource(
      host: import_host,
      path: import_path,
      params: {token: @workbench_import.token_download}).body
  end

  def execute_post eg_name, eg_file
    logger.info  "HTTP POST #{export_url} (for #{complete_entry_group_name(eg_name)})"
    HTTPService.post_resource(
      host: export_host,
      path: export_path,
      params: params(eg_file, eg_name))
  end

  def upload zip_service
    entry_group_files = zip_service.subdirs
    @workbench_import.update total_steps: entry_group_files.size
    entry_group_files.each_with_index(&method(:upload_entry_group))
  rescue Exception => e
    logger.error e.message
    @workbench_import.update( current_step: entry_group_files.size, status: 'failed' )
    raise
  end

  def upload_entry_group entry_pair, element_count
    @workbench_import.update( current_step: element_count.succ )
    eg_name     = entry_pair.name
    eg_filename = entry_pair.filename

    FileUtils.mkdir_p(Rails.root.join('tmp', 'imports'))

    #eg_file = File.new(Rails.root.join('tmp', 'imports', "WorkbenchImport_#{eg_name}_#{$$}.zip"), 'wb').tap do |file|
    eg_file = File.new(eg_filename)
    result = execute_post eg_name, eg_file
    if result && result.status < 400
      result
    else
      raise StopIteration, result.body
    end
  ensure
    # N.B. IIANM we can unlink the uploaded file as Java will access the copy kept by Carrier Wave in its
    # cache.
    # Therefore we do not need to remove this file in one of the cronjobs.
    # However the question arises: Who cleans out Carrier Wave's cache, and **when**?
    eg_file.close rescue nil
    eg_file.unlink rescue nil
  end


  # Queries
  # =======

  def complete_entry_group_name entry_group_name
    [@workbench_import.name, entry_group_name].join("--")
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
    @__import_path__ ||= download_workbench_import_path(@workbench_import.workbench, @workbench_import)
  end
  def import_url
    @__import_url__ ||= File.join(import_host, import_path)
  end

  def params file, name
    { netex_import:
        { parent_id: @workbench_import.id,
          parent_type: @workbench_import.class.name,
          workbench_id: @workbench_import.workbench_id,
          name: name,
          file: HTTPService.upload(file, 'application/zip', "#{name}.zip") } }
  end
end
