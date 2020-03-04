CarrierWave.configure do |config|
  config.cache_dir = Rails.root.join 'tmp/uploads'

  if Rails.env.test?
    config.storage = :file
    return
  end

  raise "CarrierWave initializer error: Unknown CarrierWave storage strategy" unless ['file', 'gcloud'].include? SmartEnv['STORAGE']

  config.storage = SmartEnv['STORAGE'].to_sym

  return if SmartEnv['STORAGE'] == 'file'

  raise "CarrierWave initializer error: No gcloud project specified (use GCLOUD_PROJECT environment variable)" if SmartEnv['GCLOUD_PROJECT'].blank?

  config.gcloud_bucket                       = SmartEnv['GCLOUD_BUCKET']
  config.gcloud_bucket_is_public             = SmartEnv['GCLOUD_BUCKET_IS_PUBLIC']
  config.gcloud_authenticated_url_expiration = SmartEnv['GCLOUD_AUTHENTICATED_URL_EXPIRATION']

  config.gcloud_attributes = {
    expires: SmartEnv['GCLOUD_AUTHENTICATED_URL_EXPIRATION']
  }

  config.gcloud_credentials = {
    gcloud_project: SmartEnv['GCLOUD_PROJECT'],
    gcloud_keyfile: SmartEnv['GCLOUD_KEYFILE']
  }
end

CarrierWave.tmp_path = Dir.tmpdir
