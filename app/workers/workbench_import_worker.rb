class WorkbenchImportWorker
  include Sidekiq::Worker
  include Rails.application.routes.url_helpers
  include Configurable


  # Workers
  # =======

  def perform(import_id)
    @import = Import.find(import_id)
    @downloaded = nil
    download
    @zip_service = ZipService.new(@zipfile_data)
    upload
  end

  def download
    logger.warn  "HTTP GET #{import_url}"
    @zipfile_data = HTTPService.get_resource(
      host: import_host,
      path: import_path,
      params: {token: @import.token_download})

    # TODO: Delete me after stable implementation of #1726
    # path = File.join(config.dir, import.name.gsub(%r{\s+}, '-'))
    # unique_path = FileService.unique_filename path
    # Dir.mkdir unique_path
    # @downloaded = File.join(unique_path, import.name)
    # File.open(downloaded, 'wb') do | file |
    #   file.write zipfile_data
    # end
  end

  def log_failure reason, count
    logger.warn "HTTP POST failed with #{reason}, count = #{count}"
  end

  def try_again
    raise RetryService::Retry
  end

  def upload
    @zip_service.entry_group_streams.each(&method(:upload_entry_group))
  end

  def upload_entry_group key_pair
    retry_service = RetryService.new(delay: RETRY_DELAYS, rescue_from: Timeout, &method(:log_failure)) 
  end

  def try_upload_entry_group key_pair
    eg_name, eg_stream = key_pair
    logger.warn  "HTTP POST #{export_url} (for #{complete_entry_group_name(eg_name)})"
    HTTPService.post_resource(
      host: export_host,
      path: export_path,
      resource_name: 'netex_import',
      token: token(eg_name),
      params: params,
      upload: {file: [eg_stream, 'application/zip', eg_name]})
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
