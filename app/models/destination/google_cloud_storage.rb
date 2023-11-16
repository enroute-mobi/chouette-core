# frozen_string_literal: true

class Destination::GoogleCloudStorage < ::Destination
  require "google/cloud/storage"

  option :project
  option :bucket

  validates :project, presence: true
  validates :bucket, presence: true

  @secret_file_required = true

  def do_transmit(publication, report)
    secret_file.cache!

    publication.exports.each do |export|
      next unless export[:file].present?

      upload_to_google_cloud export.file if export[:file]
    end
  end

  def upload_to_google_cloud file
    storage = Google::Cloud::Storage.new(
      project_id: self.project,
      credentials: secret_file.path
    )
    bucket = storage.bucket self.bucket, skip_lookup: true
    file.cache!
    bucket.create_file(file.path, File.basename(file.path))
  end
end
