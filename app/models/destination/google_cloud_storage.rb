# frozen_string_literal: true

class Destination
  class GoogleCloudStorage < ::Destination
    require 'google/cloud/storage'

    option :project
    option :bucket

    validates :project, presence: true
    validates :bucket, presence: true

    @secret_file_required = true

    def do_transmit(publication, _report)
      secret_file.cache!

      return unless (export = publication.export)
      return if export[:file].blank?

      upload_to_google_cloud export.file if export[:file]
    end

    def upload_to_google_cloud(file)
      storage = Google::Cloud::Storage.new(
        project_id: project,
        credentials: secret_file.path
      )
      bucket = storage.bucket self.bucket, skip_lookup: true
      file.cache!
      bucket.create_file(file.path, File.basename(file.path))
    end
  end
end
