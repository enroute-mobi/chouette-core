CarrierWave.configure do |config|
  config.cache_dir = Rails.root.join 'tmp/uploads'

  # unless Rails.env.test? or Rails.env.cucumber?
  # config.storage = :file

  config.storage                             = :gcloud
  config.gcloud_bucket                       = 'chouette-core-local'
  config.gcloud_bucket_is_public             = false
  config.gcloud_authenticated_url_expiration = 600

  config.gcloud_attributes = {
    expires: 600
  }

  config.gcloud_credentials = {
    gcloud_project: 'test-alban-250508',
    gcloud_keyfile: 'storage-key.json'
  }
end

CarrierWave.tmp_path = Dir.tmpdir
