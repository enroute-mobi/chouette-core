class WorkbenchImportWorker
  include Sidekiq::Worker
  include Rails.application.routes.url_helpers
  include Configurable

  RETRY_DELAYS = [3, 5, 8]

  # Workers
  # =======

  def perform(import_id)
    @import     = Import.find(import_id)
    @response   = nil
    downloaded  = download
    zip_service = ZipService.new(downloaded)
    upload zip_service
  end

  def download
    logger.warn  "HTTP GET #{import_url}"
    @zipfile_data = HTTPService.get_resource(
      host: import_host,
      path: import_path,
      params: {token: @import.token_download})
  end

  def execute_post eg_name, eg_stream
    logger.info  "HTTP POST #{export_url} (for #{complete_entry_group_name(eg_name)})"
    HTTPService.post_resource(
      host: export_host,
      path: export_path,
      resource_name: 'netex_import',
      token: token(eg_name),
      params: params,
      upload: {file: [eg_stream, 'application/zip', eg_name]})
  end

  def log_failure reason, count
    logger.info "HTTP POST failed with #{reason}, count = #{count}, response=#{@response}"
  end

  def try_again
    raise RetryService::Retry
  end

  def try_upload_entry_group eg_name, eg_stream
    result = execute_post eg_name, eg_stream
    return result if result.status < 400
    @response = result.body
    try_again
  end

  def upload zip_service
    zip_service.entry_group_streams.each(&method(:upload_entry_group))
  end

  def upload_entry_group key_pair
    retry_service = RetryService.new(delay: RETRY_DELAYS, rescue_from: HTTPService::Timeout, &method(:log_failure)) 
    retry_service.execute(&upload_entry_group_proc(key_pair))
  end

  def upload_entry_group_proc key_pair
    eg_name, eg_stream = key_pair
    # This should be fn.try_upload_entry_group(eg_name, eg_stream) ;(
    -> do
      try_upload_entry_group(eg_name, eg_stream)
    end
  end



  # Queries
  # =======

  def complete_entry_group_name entry_group_name
    [@import.name, entry_group_name].join("--")
  end

  def token entry_group_name
    Api::V1::ApiKey.from(@import.referential, name: complete_entry_group_name(entry_group_name)).token
  end

  # Constants
  # =========

  def export_host
    Rails.application.config.front_end_host
  end
  def export_path
    '/api/v1/netex_imports.json'
  end
  def export_url
    @__export_url__ ||= File.join(export_host, export_path)
  end

  def import_host
    Rails.application.config.front_end_host
  end
  def import_path
    @__import_path__ ||= File.join(download_workbench_import_path(@import.workbench, @import))
  end
  def import_url
    @__import_url__ ||= File.join(import_host, import_path)
  end

  def params
    @__params__ ||= { referential_id: @import.referential_id, workbench_id: @import.workbench_id }
  end
end
